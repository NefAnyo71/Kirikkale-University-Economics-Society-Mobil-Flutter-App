import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart'; // For SimpleLoginPage
import 'services/app_update_service.dart';

class AccountSettingsPage extends StatefulWidget {
  final String userName;
  final String userSurname;
  final String userEmail;

  const AccountSettingsPage({
    Key? key,
    required this.userName,
    required this.userSurname,
    required this.userEmail,
  }) : super(key: key);

  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all local data

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const BasitGirisEkrani()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool isCurrentPasswordVisible = false;
    bool isNewPasswordVisible = false;
    bool isConfirmPasswordVisible = false;
    bool isLoading = false;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          Future<void> performPasswordChange() async {
            if (!formKey.currentState!.validate()) return;

            setState(() => isLoading = true);

            try {
              final prefs = await SharedPreferences.getInstance();
              final storedPassword = prefs.getString('password');

              if (storedPassword != currentPasswordController.text) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Mevcut şifre hatalı.'),
                        backgroundColor: Colors.red),
                  );
                }
                return;
              }

              await _firestore
                  .collection('üyelercollection')
                  .doc(widget.userEmail)
                  .update({
                'password': newPasswordController.text,
                'updatedAt': FieldValue.serverTimestamp(),
              });

              await prefs.setString('password', newPasswordController.text);

              if (mounted) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Şifre başarıyla güncellendi'),
                      backgroundColor: Colors.green),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Şifre güncelleme hatası: $e')),
                );
              }
            } finally {
              if (mounted) {
                setState(() => isLoading = false);
              }
            }
          }

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Şifre Değiştir'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      decoration: InputDecoration(
                          labelText: 'Mevcut Şifre',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_open_outlined),
                          suffixIcon: IconButton(
                              icon: Icon(isCurrentPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () => setState(() =>
                                  isCurrentPasswordVisible =
                                      !isCurrentPasswordVisible))),
                      obscureText: !isCurrentPasswordVisible,
                      validator: (v) =>
                          v!.isEmpty ? 'Mevcut şifrenizi girin' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPasswordController,
                      decoration: InputDecoration(
                          labelText: 'Yeni Şifre',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                              icon: Icon(isNewPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () => setState(() =>
                                  isNewPasswordVisible =
                                      !isNewPasswordVisible))),
                      obscureText: !isNewPasswordVisible,
                      validator: (v) {
                        if (v == null || v.length < 4)
                          return 'En az 4 karakter girin';
                        if (v == currentPasswordController.text)
                          return 'Yeni şifre eskisiyle aynı olamaz.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: confirmPasswordController,
                      decoration: InputDecoration(
                          labelText: 'Yeni Şifre Tekrar',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                              icon: Icon(isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () => setState(() =>
                                  isConfirmPasswordVisible =
                                      !isConfirmPasswordVisible))),
                      obscureText: !isConfirmPasswordVisible,
                      validator: (v) => v != newPasswordController.text
                          ? 'Şifreler eşleşmiyor'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isLoading ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : performPasswordChange,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Kaydet'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _deleteAccount() async {
    try {
      await _firestore
          .collection('üyelercollection')
          .doc(widget.userEmail)
          .delete();
      await _logout(); // Logout after deleting
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hesap silinirken bir hata oluştu: $e')),
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hesabı Sil'),
          content: const Text(
              'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz ve tüm verileriniz kalıcı olarak silinecektir.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              child:
                  const Text('Hesabı Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deactivateAccount() async {
    try {
      await _firestore
          .collection('üyelercollection')
          .doc(widget.userEmail)
          .update({
        'hesapEngellendi': 1,
        'deactivatedAt': FieldValue.serverTimestamp(),
      });
      await _logout(); // Logout after deactivating
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Hesap devre dışı bırakılırken bir hata oluştu: $e')),
        );
      }
    }
  }

  void _showDeactivateAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hesabı Devre Dışı Bırak'),
          content: const Text(
              'Hesabınızı devre dışı bırakmak istediğinize emin misiniz? Hesabınız geçici olarak kapatılacak ve tekrar giriş yapana kadar kullanılamayacaktır.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deactivateAccount();
              },
              child: const Text('Devre Dışı Bırak',
                  style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Kaydedilmiş değerleri yükle veya varsayılanları kullan
    bool isEnabled = prefs.getBool('silent_hours_enabled') ?? false;

    final startTimeStr = prefs.getString('silent_hours_start')?.split(':');
    TimeOfDay startTime = startTimeStr != null
        ? TimeOfDay(
            hour: int.parse(startTimeStr[0]),
            minute: int.parse(startTimeStr[1]))
        : const TimeOfDay(hour: 22, minute: 0);

    final endTimeStr = prefs.getString('silent_hours_end')?.split(':');
    TimeOfDay endTime = endTimeStr != null
        ? TimeOfDay(
            hour: int.parse(endTimeStr[0]), minute: int.parse(endTimeStr[1]))
        : const TimeOfDay(hour: 8, minute: 0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0)),
              title: const Text('Sessiz Saatler'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Sessiz Saatleri Aktif Et'),
                    subtitle: const Text(
                        'Belirtilen saatler arasında bildirimler sessize alınır.'),
                    value: isEnabled,
                    onChanged: (value) {
                      setState(() => isEnabled = value);
                    },
                  ),
                  if (isEnabled) ...[
                    ListTile(
                      title: Text('Başlangıç: ${startTime.format(context)}'),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: () async {
                        final time = await showTimePicker(
                            context: context, initialTime: startTime);
                        if (time != null) setState(() => startTime = time);
                      },
                    ),
                    ListTile(
                      title: Text('Bitiş: ${endTime.format(context)}'),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: () async {
                        final time = await showTimePicker(
                            context: context, initialTime: endTime);
                        if (time != null) setState(() => endTime = time);
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal')),
                ElevatedButton(
                  onPressed: () async {
                    await prefs.setBool('silent_hours_enabled', isEnabled);
                    await prefs.setString('silent_hours_start',
                        '${startTime.hour}:${startTime.minute}');
                    await prefs.setString('silent_hours_end',
                        '${endTime.hour}:${endTime.minute}');
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ayarlar kaydedildi')),
                      );
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap Ayarları'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text('${widget.userName} ${widget.userSurname}',
                style: const TextStyle(fontSize: 18)),
            accountEmail: Text(widget.userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              child: Text(
                widget.userName.isNotEmpty
                    ? widget.userName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                    fontSize: 40.0, color: Colors.deepPurple.shade800),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade700,
            ),
          ),
          _buildSectionTitle('Hesap'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Şifre Değiştir'),
            onTap: _showChangePasswordDialog,
          ),
          ListTile(
            leading: const Icon(Icons.notifications_off_outlined),
            title: const Text('Bildirim Ayarları (Sessiz Saatler)'),
            onTap: _showNotificationSettings,
          ),
          const Divider(),
          _buildSectionTitle('Uygulama'),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: const Text('Güncelleme Kontrolü'),
            subtitle: const Text('Yeni sürüm kontrolü yap'),
            onTap: () => AppUpdateService.manualUpdateCheck(context),
          ),
          const Divider(),
          _buildSectionTitle('Oturum'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Çıkış Yap'),
            onTap: _logout,
          ),
          const Divider(),
          _buildSectionTitle('Tehlikeli Bölge', color: Colors.red.shade700),
          ListTile(
            leading:
                Icon(Icons.pause_circle_outline, color: Colors.orange.shade700),
            title: Text('Hesabı Devre Dışı Bırak',
                style: TextStyle(color: Colors.orange.shade700)),
            onTap: _showDeactivateAccountDialog,
          ),
          ListTile(
            leading:
                Icon(Icons.delete_forever_outlined, color: Colors.red.shade700),
            title: Text('Hesabı Kalıcı Olarak Sil',
                style: TextStyle(color: Colors.red.shade700)),
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: color ?? Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
