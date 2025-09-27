import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class UyeKayitBilgileri extends StatefulWidget {
  const UyeKayitBilgileri({Key? key}) : super(key: key);

  @override
  _UyeKayitBilgileriState createState() => _UyeKayitBilgileriState();
}

class _UyeKayitBilgileriState extends State<UyeKayitBilgileri> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<QueryDocumentSnapshot> _users = [];
  List<QueryDocumentSnapshot> _filteredUsers = [];
  bool _isLoading = true;
  bool _isSearching = false;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _itemsPerPage = 20;
  int _currentPage = 1;
  String _selectedFilter = 'tümü';
  Map<String, bool> _passwordVisibility = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection('üyelercollection')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _users = querySnapshot.docs;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('Kullanıcıları yükleme hatası: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<QueryDocumentSnapshot> filtered = _users;

    if (_selectedFilter == 'aktif') {
      filtered = filtered.where((user) {
        final data = user.data() as Map<String, dynamic>;
        return data['hesapEngellendi'] != 1;
      }).toList();
    } else if (_selectedFilter == 'engelli') {
      filtered = filtered.where((user) {
        final data = user.data() as Map<String, dynamic>;
        return data['hesapEngellendi'] == 1;
      }).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((user) {
        final data = user.data() as Map<String, dynamic>;
        final email = data['email']?.toString().toLowerCase() ?? '';
        final name = data['name']?.toString().toLowerCase() ?? '';
        final surname = data['surname']?.toString().toLowerCase() ?? '';

        return email.contains(query) ||
            name.contains(query) ||
            surname.contains(query);
      }).toList();
    }

    filtered.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      int comparison = 0;
      switch (_sortColumnIndex) {
        case 0:
          comparison = (aData['email'] ?? '').compareTo(bData['email'] ?? '');
          break;
        case 1:
          comparison = (aData['name'] ?? '').compareTo(bData['name'] ?? '');
          break;
        case 2:
          comparison = (aData['surname'] ?? '').compareTo(bData['surname'] ?? '');
          break;
        case 3:
          final aStatus = aData['hesapEngellendi'] == 1 ? 1 : 0;
          final bStatus = bData['hesapEngellendi'] == 1 ? 1 : 0;
          comparison = aStatus.compareTo(bStatus);
          break;
        case 4:
          final aDate = aData['createdAt'] as Timestamp?;
          final bDate = bData['createdAt'] as Timestamp?;
          comparison = (aDate?.millisecondsSinceEpoch ?? 0)
              .compareTo(bDate?.millisecondsSinceEpoch ?? 0);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    setState(() {
      _filteredUsers = filtered;
      _currentPage = 1;
    });
  }

  List<QueryDocumentSnapshot> get _paginatedUsers {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredUsers.length > startIndex
        ? _filteredUsers.sublist(
        startIndex,
        endIndex > _filteredUsers.length ? _filteredUsers.length : endIndex)
        : [];
  }

  int get _totalPages => (_filteredUsers.length / _itemsPerPage).ceil();

  Future<void> _toggleUserStatus(QueryDocumentSnapshot user, bool currentlyBlocked) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentlyBlocked ? 'Engeli Kaldır' : 'Kullanıcıyı Engelle'),
        content: Text(
          currentlyBlocked
              ? '${user['email']} kullanıcısının engelini kaldırmak istediğinize emin misiniz?'
              : '${user['email']} kullanıcısını engellemek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await user.reference.update({
                  'hesapEngellendi': currentlyBlocked ? 0 : 1,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        currentlyBlocked
                            ? 'Kullanıcı engeli kaldırıldı'
                            : 'Kullanıcı engellendi'
                    ),
                    backgroundColor: currentlyBlocked ? Colors.green : Colors.red,
                  ),
                );

                await _loadUsers();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('İşlem sırasında hata oluştu: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(currentlyBlocked ? 'Engeli Kaldır' : 'Engelle'),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(QueryDocumentSnapshot user) {
    final data = user.data() as Map<String, dynamic>;
    final userId = user.id;
    final isPasswordVisible = _passwordVisibility[userId] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue[50]!, Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kullanıcı Detayları',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor: data['hesapEngellendi'] == 1
                                ? Colors.red
                                : Colors.green,
                            child: Icon(
                              data['hesapEngellendi'] == 1
                                  ? Icons.block
                                  : Icons.verified_user,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildDetailCard('Kişisel Bilgiler', [
                        _buildDetailRow('E-posta', data['email'] ?? 'Belirtilmemiş', Icons.email),
                        _buildDetailRow('Ad', data['name'] ?? 'Belirtilmemiş', Icons.person),
                        _buildDetailRow('Soyad', data['surname'] ?? 'Belirtilmemiş', Icons.person_outline),
                        _buildPasswordRow(
                            'Şifre',
                            data['password'] ?? 'Belirtilmemiş',
                            isPasswordVisible,
                                () {
                              setState(() {
                                _passwordVisibility[userId] = !isPasswordVisible;
                              });
                            }
                        ),
                      ]),
                      SizedBox(height: 16),
                      _buildDetailCard('Hesap Bilgileri', [
                        _buildDetailRow('Durum',
                            data['hesapEngellendi'] == 1 ? 'Engelli' : 'Aktif',
                            data['hesapEngellendi'] == 1 ? Icons.block : Icons.check_circle,
                            valueColor: data['hesapEngellendi'] == 1 ? Colors.red : Colors.green
                        ),
                        _buildDetailRow('Oluşturulma',
                            data['createdAt'] != null
                                ? _formatTimestamp(data['createdAt'])
                                : 'Belirtilmemiş',
                            Icons.calendar_today
                        ),
                        _buildDetailRow('Son Güncelleme',
                            data['updatedAt'] != null
                                ? _formatTimestamp(data['updatedAt'])
                                : 'Belirtilmemiş',
                            Icons.update
                        ),
                      ]),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.content_copy, size: 18),
                            label: Text('Kopyala'),
                            onPressed: () {
                              final userInfo = '''
E-posta: ${data['email'] ?? 'Belirtilmemiş'}
Ad: ${data['name'] ?? 'Belirtilmemiş'}
Soyad: ${data['surname'] ?? 'Belirtilmemiş'}
Şifre: ${data['password'] ?? 'Belirtilmemiş'}
Durum: ${data['hesapEngellendi'] == 1 ? 'Engelli' : 'Aktif'}
Oluşturulma: ${data['createdAt'] != null ? _formatTimestamp(data['createdAt']) : 'Belirtilmemiş'}
Güncelleme: ${data['updatedAt'] != null ? _formatTimestamp(data['updatedAt']) : 'Belirtilmemiş'}
                            ''';
                              Clipboard.setData(ClipboardData(text: userInfo));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Bilgiler panoya kopyalandı')),
                              );
                            },
                          ),
                          ElevatedButton.icon(
                            icon: Icon(
                              data['hesapEngellendi'] == 1 ? Icons.lock_open : Icons.block,
                              size: 18,
                            ),
                            label: Text(data['hesapEngellendi'] == 1 ? 'Aç' : 'Engelle'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: data['hesapEngellendi'] == 1 ? Colors.green : Colors.red,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _toggleUserStatus(user, data['hesapEngellendi'] == 1);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
      ),
    );
  }

  Widget _buildPasswordRow(String label, String value, bool isVisible, VoidCallback onToggle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.lock, size: 18, color: Colors.blue[700]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isVisible ? value : '•' * 8,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isVisible ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: Colors.blue[700],
                      ),
                      onPressed: onToggle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue[700]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
    return 'Belirtilmemiş';
  }

  Widget _buildStatsCard() {
    final totalUsers = _users.length;
    final activeUsers = _users.where((user) {
      final data = user.data() as Map<String, dynamic>;
      return data['hesapEngellendi'] != 1;
    }).length;
    final blockedUsers = totalUsers - activeUsers;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue, Colors.blue[800]!],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Toplam', totalUsers, Icons.people),
            _buildStatItem('Aktif', activeUsers, Icons.check_circle),
            _buildStatItem('Engelli', blockedUsers, Icons.block),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _deleteUser(QueryDocumentSnapshot user) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Hesabı Sil', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(
          '${user['email']} kullanıcısının hesabını kalıcı olarak silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz!',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await user.reference.delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kullanıcı hesabı silindi'),
                    backgroundColor: Colors.red,
                  ),
                );
                await _loadUsers();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Silme işlemi sırasında hata oluştu: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(QueryDocumentSnapshot user) {
    final data = user.data() as Map<String, dynamic>;
    final isBlocked = data['hesapEngellendi'] == 1;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isBlocked 
                ? [Colors.red[50]!, Colors.red[100]!]
                : [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isBlocked ? Colors.red : Colors.blue,
                    child: Text(
                      (data['name'] ?? 'U')[0].toUpperCase(),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${data['name'] ?? ''} ${data['surname'] ?? ''}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isBlocked ? Colors.red[800] : Colors.blue[800],
                          ),
                        ),
                        Text(
                          data['email'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isBlocked ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isBlocked ? 'Engelli' : 'Aktif',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'Kayıt: ${data['createdAt'] != null ? _formatTimestamp(data['createdAt']) : 'Bilinmiyor'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.visibility,
                    label: 'Detay',
                    color: Colors.blue,
                    onPressed: () => _showUserDetails(user),
                  ),
                  _buildActionButton(
                    icon: isBlocked ? Icons.lock_open : Icons.block,
                    label: isBlocked ? 'Aç' : 'Engelle',
                    color: isBlocked ? Colors.green : Colors.orange,
                    onPressed: () => _toggleUserStatus(user, isBlocked),
                  ),
                  _buildActionButton(
                    icon: Icons.delete_forever,
                    label: 'Sil',
                    color: Colors.red,
                    onPressed: () => _deleteUser(user),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label, style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Üye Yönetimi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportData,
            tooltip: 'Dışa Aktar',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                _buildStatsCard(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Kullanıcı ara...',
                              prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters();
                                },
                              )
                                  : null,
                            ),
                            onChanged: (value) => _applyFilters(),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: PopupMenuButton<String>(
                          onSelected: (value) {
                            setState(() {
                              _selectedFilter = value;
                              _applyFilters();
                            });
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'tümü', child: Text('Tümü')),
                            PopupMenuItem(value: 'aktif', child: Text('Aktif')),
                            PopupMenuItem(value: 'engelli', child: Text('Engelli')),
                          ],
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.filter_list, color: Colors.deepPurple),
                                SizedBox(width: 4),
                                Text(
                                  _selectedFilter == 'tümü' ? 'Tümü' :
                                  _selectedFilter == 'aktif' ? 'Aktif' : 'Engelli',
                                  style: TextStyle(color: Colors.deepPurple),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.deepPurple),
                  SizedBox(height: 16),
                  Text('Kullanıcılar yükleniyor...', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
                : _filteredUsers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    _searchController.text.isNotEmpty
                        ? 'Aranan kriterlere uygun kullanıcı bulunamadı'
                        : 'Henüz kayıtlı kullanıcı bulunmuyor',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(top: 8, bottom: 80),
              itemCount: _paginatedUsers.length,
              itemBuilder: (context, index) {
                return _buildUserCard(_paginatedUsers[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _totalPages > 1 ? FloatingActionButton.extended(
        onPressed: () => _showPaginationDialog(),
        backgroundColor: Colors.deepPurple,
        icon: Icon(Icons.pages, color: Colors.white),
        label: Text('$_currentPage/$_totalPages', style: TextStyle(color: Colors.white)),
      ) : null,
    );
  }

  void _showPaginationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sayfa Seçimi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Toplam ${_filteredUsers.length} kullanıcı, $_totalPages sayfa'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 1 ? () {
                    setState(() => _currentPage--);
                    Navigator.pop(context);
                  } : null,
                  child: Text('Önceki'),
                ),
                Text('$_currentPage/$_totalPages'),
                ElevatedButton(
                  onPressed: _currentPage < _totalPages ? () {
                    setState(() => _currentPage++);
                    Navigator.pop(context);
                  } : null,
                  child: Text('Sonraki'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 16),
            onPressed: _currentPage > 1
                ? () {
              setState(() {
                _currentPage--;
                _scrollController.animateTo(
                  0,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              });
            }
                : null,
          ),
          Text(
            'Sayfa $_currentPage/$_totalPages (Toplam ${_filteredUsers.length} kullanıcı)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: _currentPage < _totalPages
                ? () {
              setState(() {
                _currentPage++;
                _scrollController.animateTo(
                  0,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              });
            }
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final csvData = StringBuffer();
      csvData.writeln('E-posta,Ad,Soyad,Şifre,Durum,Oluşturulma Tarihi,Son Güncelleme');

      for (final user in _users) {
        final data = user.data() as Map<String, dynamic>;
        csvData.writeln('"${data['email'] ?? ''}","${data['name'] ?? ''}","${data['surname'] ?? ''}",'
            '"${data['password'] ?? ''}","${data['hesapEngellendi'] == 1 ? 'Engelli' : 'Aktif'}","'
            '${data['createdAt'] != null ? _formatTimestamp(data['createdAt']) : ''}","'
            '${data['updatedAt'] != null ? _formatTimestamp(data['updatedAt']) : ''}"');
      }

      Clipboard.setData(ClipboardData(text: csvData.toString()));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_users.length} kullanıcı verisi panoya kopyalandı'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dışa aktarma hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}