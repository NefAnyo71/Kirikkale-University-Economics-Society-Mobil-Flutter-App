import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_logging_service.dart';
import 'BasvuruSorgulama.dart';
import 'Topluluk_Haberleri_Yönetici.dart';
import 'cleaner_admin_page.dart';
import 'oylama.dart';
import 'puanlama_sayfasi.dart';
import 'website_applications_page.dart';
import 'BlackList.dart';
import 'Cerezler.dart';
import 'DersNotlariAdmin1.dart';
import 'admin_yaklasan_etkinlikler.dart';
import 'admin_survey_page.dart';
import 'uye_kayit_bilgileri.dart';
import 'admin_logs_viewer_page.dart';
import 'admin_ai_assistant.dart';
import 'native_biometric_service.dart';
import 'nfc_service.dart';
import 'nfc_admin_management.dart';
import 'self_nfc_registration.dart';


class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({Key? key}) : super(key: key);

  @override
  _AdminPanelPageState createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  bool _isAuthenticated = false;
  String? _authenticatedAdminUsername;

  void _onLoginSuccess(String username) {
    setState(() {
      _isAuthenticated = true;
      _authenticatedAdminUsername = username;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isAuthenticated ? 'Admin Paneli' : 'Yönetici Girişi',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple.shade700,
        centerTitle: true,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _isAuthenticated
            ? _AdminDashboard(
                key: const ValueKey('AdminDashboard'),
                adminUsername: _authenticatedAdminUsername!,
              )
            : _AdminLoginScreen(
                key: const ValueKey('AdminLoginScreen'),
                onLoginSuccess: _onLoginSuccess,
              ),
      ),
    );
  }
}

class _AdminLoginScreen extends StatefulWidget {
  final Function(String) onLoginSuccess;

  const _AdminLoginScreen({Key? key, required this.onLoginSuccess})
      : super(key: key);

  @override
  __AdminLoginScreenState createState() => __AdminLoginScreenState();
}

class __AdminLoginScreenState extends State<_AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _showBiometricOption = false;
  bool _biometricAvailable = false;
  bool _showNFCOption = false;
  bool _nfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _checkNFCAvailability();
    _setupAuthorizedAdmins();
  }
  
  Future<void> _setupAuthorizedAdmins() async {
    // Firebase'e örnek yetkili adminleri ekle (sadece ilk kurulumda çalışır)
    await NFCService.addAuthorizedAdminToFirebase('12345678901', 'ADMIN USER');
    await NFCService.addAuthorizedAdminToFirebase('98765432109', 'YÖNETİCİ İKİ');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await NativeBiometricService.isBiometricAvailable();
    final isEnabled = await NativeBiometricService.isBiometricEnabled();
    
    print('🔍 Biometric Available: $isAvailable');
    print('🔍 Biometric Enabled: $isEnabled');
    
    if (mounted) {
      setState(() {
        _biometricAvailable = isAvailable;
        _showBiometricOption = isAvailable;
      });
    }
  }
  
  Future<void> _checkNFCAvailability() async {
    final isAvailable = await NFCService.isNFCAvailable();
    final isEnabled = await NFCService.isNFCEnabled();
    
    print('📱 NFC Available: $isAvailable');
    print('📱 NFC Enabled: $isEnabled');
    
    if (mounted) {
      setState(() {
        _nfcAvailable = isAvailable;
        _showNFCOption = isAvailable;
      });
    }
  }
  
  Future<void> _authenticateWithNFC() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('📱 NFC kimlik doğrulama başlatılıyor...');
      
      if (!await NFCService.isNFCEnabled()) {
        setState(() {
          _errorMessage = 'NFC kapalı. Lütfen NFC\'yi aktif edin.';
          _isLoading = false;
        });
        await NFCService.openNFCSettings();
        return;
      }
      
      final tcData = await NFCService.readTCKimlik();
      print('📱 TC Kimlik sonucu: $tcData');
      
      if (tcData != null && tcData['tcNo']!.isNotEmpty) {
        final tcNo = tcData['tcNo']!;
        final isAuthorized = await NFCService.isAuthorizedAdmin(tcNo);
        
        if (isAuthorized) {
          // Son giriş tarihini güncelle
          await NFCService.updateLastLogin(tcNo);
          
          await AdminLoggingService.logLoginAttempt(
            adminUsername: '${tcData['ad']} ${tcData['soyad']} ($tcNo)',
            isSuccessful: true,
          );
          widget.onLoginSuccess('${tcData['ad']} ${tcData['soyad']}');
          return;
        } else {
          setState(() {
            _errorMessage = 'Bu TC kimlik numarası yetkili değil: $tcNo';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'TC Kimlik kartı okunamadı. Kartı cihaza yaklaştırın.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('📱 NFC hata: $e');
      setState(() {
        _errorMessage = 'NFC okuma hatası: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔐 Biometric authentication başlatılıyor...');
      final authenticated = await NativeBiometricService.authenticateWithBiometric();
      print('🔐 Biometric sonuç: $authenticated');
      
      if (authenticated) {
        final credentials = await NativeBiometricService.getSavedAdminCredentials();
        print('🔐 Kaydedilmiş credentials: ${credentials != null}');
        
        if (credentials != null) {
          final isValid = await _validateCredentials(
            credentials['username']!, 
            credentials['password']!
          );
          
          if (isValid) {
            await AdminLoggingService.logLoginAttempt(
              adminUsername: credentials['username']!,
              isSuccessful: true,
            );
            widget.onLoginSuccess(credentials['username']!);
            return;
          }
        } else {
          // Eğer kayıtlı credential yoksa, kullanıcıdan giriş yapmasını iste
          setState(() {
            _errorMessage = 'İlk önce normal giriş yaparak biometric ayarlayın';
            _isLoading = false;
          });
          return;
        }
      }
      
      setState(() {
        _errorMessage = 'Biometric kimlik doğrulama başarısız';
        _isLoading = false;
      });
    } catch (e) {
      print('🔐 Biometric hata: $e');
      setState(() {
        _errorMessage = 'Biometric kimlik doğrulama hatası: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _attemptLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      final isValid = await _validateCredentials(username, password);

      // Giriş denemesini logla
      await AdminLoggingService.logLoginAttempt(
        adminUsername: username,
        isSuccessful: isValid,
      );

      if (mounted) {
        if (isValid) {
          // Başarılı giriş sonrası biometric kaydet
          if (_biometricAvailable && !await NativeBiometricService.isBiometricEnabled()) {
            await _showBiometricSetupDialog(username, password);
          } else {
            await NativeBiometricService.saveAdminCredentials(username, password);
          }
          widget.onLoginSuccess(username);
        } else {
          setState(() {
            _errorMessage = 'Kullanıcı adı veya şifre hatalı.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Giriş sırasında bir hata oluştu.';
          _isLoading = false;
        });
      }
      print("Giriş hatası: $e");
    }
  }

  Future<void> _showBiometricSetupDialog(String username, String password) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biometric Kimlik Doğrulama'),
        content: const Text(
          'Gelecekteki girişler için parmak izi veya yüz tanıma kullanmak ister misiniz?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet'),
          ),
        ],
      ),
    );

    if (result == true) {
      await NativeBiometricService.saveAdminCredentials(username, password);
      setState(() {
        _showBiometricOption = true;
      });
    }
  }

  Future<bool> _validateCredentials(String username, String password) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('adminpanelcollection')
          .where('kullanici_adi', isEqualTo: username)
          .where('sifre', isEqualTo: password)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Firebase doğrulama hatası: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade300, Colors.cyan.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 60,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Yönetici Girişi',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Kullanıcı Adı',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen kullanıcı adınızı girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen şifrenizi girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.login),
                              onPressed: _attemptLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              label: const Text('GİRİŞ YAP'),
                            ),
                          ),
                          if (_showBiometricOption) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.fingerprint),
                                onPressed: _authenticateWithBiometrics,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.deepPurple,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                label: const Text('BİOMETRİK GİRİŞ'),
                              ),
                            ),
                          ],
                          if (_showNFCOption) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.nfc),
                                onPressed: _authenticateWithNFC,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                label: const Text('TC KİMLİK NFC GİRİŞ'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _errorMessage,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
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

class _AdminDashboard extends StatelessWidget {
  final String adminUsername;

  const _AdminDashboard({Key? key, required this.adminUsername})
      : super(key: key);

  void _handleNavigation(
      BuildContext context, String label, Widget destinationPage) {
    // Yönlendirme aksiyonunu logla
    AdminLoggingService.logNavigation(
      adminUsername: adminUsername,
      buttonLabel: label,
    );
    // Sayfaya yönlendir
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destinationPage),
    );
  }

  Widget _buildAdminButton(
    BuildContext context,
    String label,
    IconData icon,
    Widget destinationPage,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleNavigation(context, label, destinationPage),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28, color: Colors.black), // İkon rengi siyah
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black, // Buton metin rengi siyah
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right,
                  color: Colors.black), // Ok ikonu siyah
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.deepPurple.shade50,
            Colors.blue.shade50,
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildAdminButton(
            context,
            'Yaklaşan Etkinlikler',
            Icons.event_available,
            EtkinlikJson5(),
          ),
          _buildAdminButton(
            context,
            'Etkinlik Takvimi',
            Icons.calendar_today,
            CleanderAdminPage(),
          ),
          _buildAdminButton(
            context,
            'Topluluk Haberleri',
            Icons.newspaper,
            ToplulukHaberleriSayfasi(),
          ),
          _buildAdminButton(
            context,
            'Oylama Ekranı',
            Icons.how_to_vote,
            VotingScreen(),
          ),
          _buildAdminButton(
            context,
            'İnternet Sitesi Başvuruları',
            Icons.web,
            WebsiteApplicationsPage(),
          ),
          _buildAdminButton(
            context,
            'Öğrenci Veri Tabanı',
            Icons.storage,
            BasvuruSorgulama(),
          ),
          _buildAdminButton(
            context,
            'Karaliste',
            Icons.block,
            KaraListe(),
          ),
          _buildAdminButton(
            context,
            'Yapay Zeka Puanlama Sistemi',
            Icons.auto_awesome,
            PuanlamaSayfasi(),
          ),
          _buildAdminButton(
            context,
            'İnternet Sitesi Çerezleri',
            Icons.cookie,
            SiteSessionsWidget(),
          ),
          _buildAdminButton(
            context,
            'Ders Notu Paylaşım Sistemi',
            Icons.menu_book,
            DersNotlariAdmin1(),
          ),
          _buildAdminButton(
            context,
            'Anketler ve Geri Bildirimler',
            Icons.poll,
            SurveyPage1(),
          ),
          _buildAdminButton(
            context,
            'Üye Kayıt Bilgileri',
            Icons.people,
            UyeKayitBilgileri(),
          ),
          _buildAdminButton(
            context,
            'Yönetici Aktivite Logları',
            Icons.history,
            const AdminLogsViewerPage(),
          ),
          _buildAdminButton(
            context,
            'KET Groq AI',
            Icons.psychology,
            AdminAIAssistant(adminUsername: adminUsername),
          ),
          _buildAdminButton(
            context,
            'NFC Admin Yönetimi',
            Icons.nfc,
            NFCAdminManagement(currentAdminUsername: adminUsername),
          ),
          _buildAdminButton(
            context,
            'Kendi TC\'mi NFC\'ye Ekle',
            Icons.person_add,
            SelfNFCRegistration(currentAdminUsername: adminUsername),
          ),
        ],
      ),
    );
  }
}

