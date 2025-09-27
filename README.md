# 🎓 EKOS - Kırıkkale Üniversitesi Ekonomi Topluluğu Mobil Uygulaması

<div align="center">
  <img src="assets/images/ekoslogo.png" alt="EKOS Logo" width="200"/>
  <br>
  <strong>Kırıkkale Üniversitesi Ekonomi Topluluğu için geliştirdiğim flutter telefon uygulamam</strong>
</div>

## 📱 Proje Hakkında

KET(kku ekonomi toplululuğu), Kırıkkale Üniversitesi Ekonomi Topluluğu için Flutter ile geliştirilmiş modern bir mobil uygulamadır. Uygulama, topluluk etkinlikleri, güncel ekonomi haberleri, ders notları paylaşımı ve sosyal medya entegrasyonu gibi kapsamlı özellikler sunar.

## 🎥 Proje Tanıtım Videosu

<div align="center">
  <a href="https://www.youtube.com/watch?v=3jnqW75B0Bk" target="_blank">
    <img src="https://img.youtube.com/vi/3jnqW75B0Bk/maxresdefault.jpg" alt="KET Proje Tanıtım Videosu" width="600"/>
  </a>
  <br>
  <strong>📺 <a href="https://www.youtube.com/watch?v=3jnqW75B0Bk">KET Mobil Uygulaması ve Web Sitesi Tanıtım Videosu</a></strong>
  <br>
  <em>Projenin detaylı tanıtımı, özellikler ve kullanım rehberi</em>
</div>

---

**Sürüm**: 6.8.9
**Geliştirici**: Arif Özdemir 
**Platform**: Android (iOS desteği mevcut)  
**Dil**: Dart/Flutter  
**Veritabanı**: Firebase Firestore  
**Minimum SDK**: Android API 34 (Android 13)  
**Hedef SDK**: Android API 36 (Android 16)

## ✨ Özellikler

### 📚 Eğitim ve Akademik
- **Ders Notu Paylaşım Sistemi**: Üyeler arası ders notu paylaşımı
- **Ders Notlarım**: Kişisel ders notları yönetimi
- **Etkinlik Takvimi**: Akademik ve sosyal etkinlik takibi
- **Yaklaşan Etkinlikler**: Gelecek etkinlikler için bildirimler

### 📰 Haber ve İletişim
- **Topluluk Haberleri**: Güncel topluluk duyuruları
- **Sosyal Medya Entegrasyonu**: Topluluk sosyal medya hesaplarına erişim
- **Geri Bildirim Sistemi**: Uygulama ve topluluk hakkında görüş bildirme
- **Anket Sistemi**: Üye görüşlerini toplama

### 💰 Ekonomi ve Finans
- **Güncel Ekonomi**: Son ekonomik gelişmeler
- **Canlı Piyasa**: Gerçek zamanlı finansal veriler
- **Ekonomik Analizler**: Uzman görüşleri ve analizler

### 👥 Topluluk Yönetimi
- **Üye Kayıt Sistemi**: Yeni üye başvuruları
- **Üye Profilleri**: Topluluk üyesi bilgileri
- **Yönetici Paneli**: Topluluk yöneticileri için özel panel
- **Sponsorlar**: Topluluk sponsorları ve iş birlikleri

### 🔔 Bildirim ve Güvenlik
- **Push Bildirimleri**: Önemli duyurular için anlık bildirimler
- **Hesap Güvenliği**: Güvenli giriş ve hesap yönetimi
- **Çevrimdışı Mod**: İnternet bağlantısı olmadan bazı özellikler
- **Otomatik Güncelleme**: Uygulama güncellemelerini kontrol etme

## 🛠️ Teknolojiler

### Frontend
- **Flutter 3.6.1+** - Cross-platform mobil uygulama geliştirme
- **Dart 3.6.1+** - Programlama dili
- **Material Design 3** - Modern UI/UX tasarımı

### Backend ve Veritabanı
- **Firebase Core** - Backend altyapısı
- **Cloud Firestore** - NoSQL veritabanı
- **Firebase Authentication** - Kullanıcı kimlik doğrulama
- **Firebase Messaging** - Push bildirimleri
- **Firebase Database** - Gerçek zamanlı veritabanı

### Önemli Paketler
- **shared_preferences** - Yerel veri depolama
- **permission_handler** - Sistem izinleri yönetimi
- **url_launcher** - Harici bağlantılar
- **image_picker** - Görsel seçimi ve yükleme
- **syncfusion_flutter_charts** - Grafik ve çizelgeler
- **workmanager** - Arka plan görevleri
- **in_app_update** - Uygulama içi güncelleme
- **flutter_local_notifications** - Yerel bildirimler
- **http** - HTTP istekleri
- **intl** - Uluslararasılaştırma ve tarih formatları
- **share_plus** - İçerik paylaşımı

## 📂 Proje Yapısı ve Dart Dosyalarının İşlevleri

### 🏠 Ana Dosyalar

#### `main.dart` - Uygulama Giriş Noktası
- **İşlev**: Uygulamanın ana giriş noktası ve başlatma işlemleri
- **Özellikler**:
  - Firebase başlatma ve yapılandırma
  - Kullanıcı kimlik doğrulama sistemi
  - Splash screen ve loading ekranları
  - Uygulama güncelleme kontrolü
  - Push bildirim yapılandırması
  - Workmanager ile arka plan görevleri
  - Ana sayfa grid menü sistemi
  - Hesap engelleme kontrolü

#### `firebase_service.dart` - Firebase İşlemleri
- **İşlev**: Firebase Firestore veritabanı işlemleri
- **Özellikler**:
  - Geri bildirim ekleme/çekme
  - Turnuva başvuru yönetimi
  - Veritabanı CRUD işlemleri
  - Hata yönetimi

### 🎯 Özellik Modülleri

#### `admin_panel_page.dart` - Yönetici Paneli
- **İşlev**: Yönetici girişi ve yönetim araçları
- **Özellikler**:
  - Güvenli yönetici girişi (kullanıcı adı: kkuekonomi71)
  - Etkinlik yönetimi
  - Topluluk haberleri yönetimi
  - Oylama sistemi yönetimi
  - Öğrenci veritabanı
  - Karaliste yönetimi
  - Yapay zeka puanlama sistemi
  - Ders notu yönetimi

#### `current_economy.dart` - Güncel Ekonomi Haberleri
- **İşlev**: Anadolu Ajansı RSS beslemesinden ekonomi haberlerini çekme
- **Özellikler**:
  - RSS feed okuma ve parsing
  - Haber filtreleme sistemi
  - Karanlık/aydınlık mod
  - Haber raporlama sistemi
  - Paylaşım özelliği
  - Yasal uyarı sistemi
  - Otomatik haber güncelleme

#### `live_market.dart` - Canlı Piyasa Takibi
- **İşlev**: Kripto para ve hisse senedi fiyatlarını gerçek zamanlı takip
- **Özellikler**:
  - CoinGecko API entegrasyonu
  - Türk hisse senetleri simülasyonu
  - Favori ekleme sistemi
  - Fiyat grafikleri (Syncfusion Charts)
  - Karşılaştırma özelliği
  - Arama ve filtreleme
  - Mum grafikleri (Candlestick)

#### `ders_notlari1.dart` - Ders Notu Paylaşım Sistemi
- **İşlev**: Öğrenciler arası ders notu paylaşımı
- **Özellikler**:
  - Fakülte/bölüm/ders filtreleme
  - PDF dosya paylaşımı
  - Beğeni/beğenmeme sistemi
  - Favori ekleme
  - İndirme sayacı
  - Yasal uyarı ve kullanım koşulları
  - Anonim kullanıcı sistemi

#### `etkinlik_takvimi2.dart` - Etkinlik Takvimi
- **İşlev**: Topluluk etkinliklerini listeleme
- **Özellikler**:
  - Firebase Firestore entegrasyonu
  - Tarih sıralama
  - Görsel destekli etkinlik kartları
  - Gradient arka plan tasarımı
  - Responsive tasarım

#### `yaklasan_etkinlikler.dart` - Yaklaşan Etkinlikler
- **İşlev**: Gelecekteki etkinlikleri gösterme ve alarm kurma
- **Özellikler**:
  - Kalan süre hesaplama
  - Alarm kurma sistemi (Samsung ve diğer markalar için)
  - Intent sistemi ile saat uygulaması entegrasyonu
  - Gerçek zamanlı güncelleme

#### `social_media_page.dart` - Sosyal Medya
- **İşlev**: Topluluk sosyal medya hesaplarına yönlendirme
- **Özellikler**:
  - Instagram ve Twitter entegrasyonu
  - URL launcher ile harici bağlantılar
  - Responsive kart tasarımı

#### `feedback.dart` - Geri Bildirim Sistemi
- **İşlev**: Kullanıcı geri bildirimlerini toplama
- **Özellikler**:
  - Anonim geri bildirim
  - Firebase Firestore kayıt
  - E-posta adresi (isteğe bağlı)
  - Form validasyonu

#### `poll.dart` - Anket Sistemi
- **İşlev**: Topluluk anketleri oluşturma ve yönetme
- **Özellikler**:
  - Çoktan seçmeli sorular
  - Açık uçlu sorular
  - Firebase Firestore kayıt
  - Anonim anket sistemi

#### `sponsors_page.dart` - Sponsorlar
- **İşlev**: Sponsorluk bilgileri ve iletişim
- **Özellikler**:
  - E-posta entegrasyonu
  - Sponsorluk başvuru sistemi
  - İletişim formu

#### `account_settings_page.dart` - Hesap Ayarları
- **İşlev**: Kullanıcı hesap yönetimi
- **Özellikler**:
  - Şifre değiştirme
  - Hesap silme/devre dışı bırakma
  - Bildirim ayarları (sessiz saatler)
  - Çıkış yapma
  - Kullanıcı profil bilgileri

### 🔧 Servis Dosyaları

#### `notification_service.dart` - Bildirim Servisi
- **İşlev**: Push bildirim yönetimi ve etkinlik hatırlatmaları
- **Özellikler**:
  - Flutter Local Notifications
  - Etkinlik bazlı otomatik bildirimler
  - 7 gün, 1 gün, 1 saat öncesi hatırlatmalar
  - Bildirim geçmişi yönetimi
  - Debug ve test fonksiyonları

#### `services/local_storage_service.dart` - Yerel Depolama
- **İşlev**: SharedPreferences ile yerel veri yönetimi
- **Özellikler**:
  - Kullanıcı oturum bilgileri
  - Uygulama ayarları
  - Önbellek yönetimi

### 🔐 Yönetici Modülleri

#### `admin_yaklasan_etkinlikler.dart` - Etkinlik Yönetimi (Admin)
- **İşlev**: Yöneticiler için yaklaşan etkinlik ekleme/düzenleme
- **Özellikler**:
  - Etkinlik başlığı, detay ve tarih yönetimi
  - Görsel URL ekleme
  - Etkinlik silme ve güncelleme
  - Firebase Firestore entegrasyonu
  - Tarih ve saat seçici

#### `admin_survey_page.dart` - Anket Sonuçları Yönetimi
- **İşlev**: Anket sonuçlarını görüntüleme ve analiz etme
- **Özellikler**:
  - Uygulama değerlendirme istatistikleri
  - Özel bar grafik sistemi
  - Kullanıcı geri bildirimlerini kategorize etme
  - Topluluk, uygulama ve etkinlik geri bildirimleri
  - Gerçek zamanlı veri güncelleme

#### `cleaner_admin_page.dart` - Temizlik Yönetimi
- **İşlev**: Veritabanı temizleme ve bakım işlemleri

#### `Topluluk_Haberleri_Yönetici.dart` - Haber Yönetimi
- **İşlev**: Topluluk haberlerini ekleme/düzenleme

#### `BlackList.dart` - Karaliste Yönetimi
- **İşlev**: Kullanıcı engelleme sistemi

#### `puanlama_sayfasi.dart` - Yapay Zeka Puanlama
- **İşlev**: Öğrenci performans değerlendirme sistemi

### 📊 Veri Modelleri ve Yardımcı Dosyalar

#### `ders_notlari1_new.dart` - Gelişmiş Ders Notu Sistemi
- **İşlev**: Yeni nesil ders notu paylaşım sistemi
- **Özellikler**:
  - Kapsamlı yasal uyarı sistemi
  - Kullanıcı onay mekanizması
  - Favori ekleme sistemi
  - Beğeni/beğenmeme sistemi
  - İndirme sayacı
  - Anonim kullanıcı desteği
  - Gelişmiş arama ve filtreleme

#### `DersNotlariAdmin1.dart` - Ders Notları Yönetici Paneli
- **İşlev**: Yöneticiler için ders notu yönetimi
- **Özellikler**:
  - Not ekleme/düzenleme/silme
  - Arama ve filtreleme
  - Görsel destekli not kartları
  - Dönem ve sınav türü yönetimi

#### `DersNotlarimPage.dart` - Kişisel Ders Notları
- **İşlev**: Kullanıcıların kişisel ders notlarını yönetmesi
- **Özellikler**:
  - Ders ekleme/silme
  - Vize ve final fotoğrafları
  - Yerel depolama sistemi
  - Görsel yönetimi

#### `uye_kayit_bilgileri.dart` - Üye Kayıt Bilgileri Yönetimi
- **İşlev**: Kayıtlı üyelerin bilgilerini görüntüleme ve yönetme
- **Özellikler**:
  - Kullanıcı arama ve filtreleme sistemi
  - Sayfalama (pagination) desteği
  - Kullanıcı hesap durumu yönetimi (aktif/engelli)
  - Şifre görünürlük kontrolü
  - Veri dışa aktarma (CSV formatında)
  - Detaylı kullanıcı profil görüntüleme
  - Sıralama ve filtreleme seçenekleri

#### `oylama.dart` - Oylama Sistemi
- **İşlev**: Topluluk oylamaları oluşturma ve yönetme
- **Özellikler**:
  - Çoktan seçmeli oylama
  - Kullanıcı başına tek oy hakkı
  - Gerçek zamanlı sonuç görüntüleme
  - Oylama silme yetkisi
  - SharedPreferences ile oy takibi

#### `Cerezler.dart` - Site Oturum Takibi
- **İşlev**: Web sitesi oturum verilerini analiz etme
- **Özellikler**:
  - IP adresi takibi
  - Oturum süresi analizi
  - Kullanıcı onay durumu
  - Çıkış takibi
  - Benzersiz ziyaretçi sayısı

#### `BasvuruSorgulama.dart` - Başvuru Yönetim Sistemi
- **İşlev**: Gezi ve etkinlik başvurularını yönetme
- **Özellikler**:
  - Başvuru arama ve filtreleme
  - Ödeme durumu takibi
  - Başvuru silme (çift onay sistemi)
  - Gerçek zamanlı başvuru sayısı
  - Detaylı başvuru bilgileri

#### `adminFeedBack.dart` - Geri Bildirim Yönetimi
- **İşlev**: Kullanıcı geri bildirimlerini yönetme
- **Özellikler**:
  - Firebase entegrasyonu
  - Geri bildirim listeleme
  - Yenileme özelliği
  - Gradient arka plan tasarımı

#### `community_news2_page.dart` - Topluluk Haberleri Görüntüleme
- **İşlev**: Topluluk haberlerini kullanıcılara gösterme
- **Özellikler**:
  - Tarih sıralı haber listeleme
  - Görsel destekli haberler
  - Gradient arka plan
  - Gerçek zamanlı haber güncelleme

#### `uyekayıt.dart` / `uye_kayit.dart` - Üye Kayıt
- **İşlev**: Yeni üye kayıt işlemleri

#### `member_profiles_account.dart` - Üye Profilleri
- **İşlev**: Üye profil bilgileri yönetimi

#### `website_applications_page.dart` - Web Başvuruları
- **İşlev**: İnternet sitesi başvurularını yönetme

## 🚀 Kurulum

### Gereksinimler
- Flutter SDK 3.6.1 veya üzeri
- Dart SDK 3.6.1 veya üzeri
- Android Studio / VS Code
- Java 17 (Android geliştirme için)
- Gradle 8.12
- Firebase hesabı ve proje yapılandırması
- Android SDK (API Level 21 veya üzeri)

### Adım Adım Kurulum

1. **Flutter'ı yükleyin**:
   ```bash
   # Flutter'ın yüklü olduğunu kontrol edin
   flutter doctor
   ```

2. **Projeyi klonlayın**:
   ```bash
   git clone [repository-url]
   cd ket
   ```

3. **Bağımlılıkları yükleyin**:
   ```bash
   flutter pub get
   ```

4. **Firebase yapılandırması**:
   - `android/app/google-services.json` dosyasını ekleyin
   - Firebase Console'da projenizi yapılandırın

5. **Uygulamayı çalıştırın**:
   ```bash
   flutter run
   ```

## 📋 Yapılandırma

### Firebase Kurulumu
1. Firebase Console'da yeni proje oluşturun
2. Android uygulaması ekleyin (com.example.ekos)
3. `google-services.json` dosyasını `android/app/` klasörüne yerleştirin
4. Firebase Authentication, Firestore, Cloud Messaging ve Realtime Database'i etkinleştirin
5. Güvenlik kurallarını yapılandırın

### Gerekli İzinler (Android)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### Uygulama Yapılandırması
1. `pubspec.yaml` dosyasındaki bağımlılıkları kontrol edin
2. Firebase yapılandırma dosyalarını yerleştirin
3. Android imzalama sertifikalarını yapılandırın
4. Bildirim kanallarını ayarlayın

## 🔧 Geliştirme Ortamı

### Debug Modu
```bash
flutter run --debug
```

### Release Modu
```bash
flutter build apk --release
```

### Profil Modu (Performans Analizi)
```bash
flutter run --profile
```

## 📱 Uygulama Mimarisi

### Klasör Yapısı
```
lib/
├── services/           # Servis katmanı
│   ├── local_storage_service.dart
│   └── notification_service.dart
├── admin/             # Yönetici paneli
├── pages/             # Ana sayfalar
├── widgets/           # Yeniden kullanılabilir bileşenler
└── main.dart          # Uygulama giriş noktası
```

### Veri Akışı
1. **Firebase Firestore**: Ana veritabanı
2. **SharedPreferences**: Yerel ayarlar
3. **Firebase Auth**: Kullanıcı kimlik doğrulama
4. **Firebase Messaging**: Push bildirimleri

## 🔐 Güvenlik Özellikleri

### Kullanıcı Kimlik Doğrulama
- Firebase Authentication entegrasyonu
- Anonim giriş desteği
- Hesap engelleme sistemi
- Güvenli şifre yönetimi

### Veri Güvenliği
- Firestore güvenlik kuralları
- Kullanıcı verilerinin şifrelenmesi
- API anahtarlarının güvenli saklanması
- Yasal uyarı ve kullanım koşulları

## 📊 Performans Optimizasyonu

### Veritabanı Optimizasyonu
- Firestore indeksleme
- Sayfalama (pagination)
- Gerçek zamanlı dinleyiciler
- Önbellek yönetimi

### UI/UX Optimizasyonu
- Lazy loading
- Görsel optimizasyonu
- Responsive tasarım
- Karanlık/aydınlık mod desteği

## 🧪 Test Etme

### Unit Testler
```bash
flutter test
```

### Widget Testleri
```bash
flutter test test/widget_test.dart
```

### Entegrasyon Testleri
```bash
flutter drive --target=test_driver/app.dart
```

## 📈 Analitik ve İzleme

### Firebase Analytics
- Kullanıcı davranış analizi
- Ekran görüntüleme istatistikleri
- Olay takibi
- Çökme raporları

### Performans İzleme
- Firebase Performance Monitoring
- Ağ istekleri analizi
- Uygulama başlatma süreleri
- Bellek kullanımı

## 🚀 Dağıtım

### Google Play Store
1. Uygulama imzalama
2. APK/AAB oluşturma
3. Store listeleme
4. Sürüm yönetimi

### Firebase App Distribution
1. Test kullanıcıları ekleme
2. Beta sürüm dağıtımı
3. Geri bildirim toplama

## 🔄 Güncelleme Sistemi

### Otomatik Güncelleme
- In-app update API
- Zorunlu güncelleme kontrolü
- Kullanıcı bilgilendirme
- Güncelleme durumu takibi

## 📞 Destek ve İletişim

### Geliştirici İletişim
- **E-posta**: arifkerem71@gmail.com
- **Topluluk**: Kırıkkale Üniversitesi Ekonomi Topluluğu

### Hata Bildirimi
1. GitHub Issues kullanın
2. Detaylı hata açıklaması ekleyin
3. Ekran görüntüleri paylaşın
4. Cihaz ve sürüm bilgilerini belirtin

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için `LICENSE` dosyasına bakınız.

## 🙏 Katkıda Bulunanlar

- **Arif Özdemir** - Ana Geliştirici
- **Kırıkkale Üniversitesi Ekonomi Topluluğu** - Proje Sponsoru

## 📝 Sürüm Geçmişi

### v6.8.9 (Güncel)
- Gelişmiş ders notu paylaşım sistemi
- Yönetici paneli iyileştirmeleri
- Bildirim sistemi güncellemeleri
- Performans optimizasyonları
- Yapayzeka Ket eklendi

### v5.x.x
- Temel özellikler
- Firebase entegrasyonu
- Kullanıcı arayüzü geliştirmeleri

## 🤖 KET Yapay Zeka Asistanı

<div align="center">
  <img src="assets/images/ketyapayzeka.png" alt="KET AI Asistan" width="120"/>
  <br>
  <strong>Google Gemini AI ile güçlendirilmiş akıllı topluluk asistanı</strong>
</div>

### 🧠 Yapay Zeka Özellikleri

#### **💬 Akıllı Sohbet Sistemi**
- **Google Gemini 1.5 Flash** modeli entegrasyonu
- **Türkçe dil desteği** ile doğal konuşma
- **KET bilgi bankası** ile özelleştirilmiş yanıtlar
- **Bağlamsal anlama** ve akıllı cevap üretme
- **Firebase database entegrasyonu** collectiondaki verilere yapayzeka erişebiliyor 

#### **🎤 Çoklu İletişim Kanalları**
- **Sesli mesaj gönderme** ve kaydetme
- **Speech-to-Text** ile sesle soru sorma
- **Text-to-Speech** ile yanıtları sesli okuma
- **Görsel analizi** ile fotoğraf gönderme ve açıklama

#### **📚 Kapsamlı Bilgi Bankası**
- **500+ topluluk bilgisi** detaylı açıklamalarla
- **Etkinlik ve organizasyon** bilgileri
- **Ders notları sistemi** rehberliği
- **Üyelik ve hesap yönetimi** desteği
- **Sorun giderme** ve teknik destek

#### **🎨 Modern Kullanıcı Arayüzü**
- **Karanlık/Aydınlık mod** desteği
- **Mesaj kopyalama** ve silme özellikleri
- **Zaman damgası** ile mesaj geçmişi
- **Sık sorulan sorular** hızlı erişim
- **Kullanım sınırları** ile adil kaynak yönetimi

#### **⚡ Performans ve Güvenlik**
- **Günlük 10 mesaj** sınırı ile kaynak optimizasyonu
- **5 dakikada 10 mesaj** spam koruması
- **Chat geçmişi** yerel depolama
- **API güvenliği** ve hata yönetimi

### 🚀 KET AI Kullanım Senaryoları

#### **📋 Topluluk Bilgileri**
```
"KET nedir?"
"Nasıl üye olabilirim?"
"Etkinlikler ücretsiz mi?"
"İletişim bilgileri neler?"
```

#### **📖 Akademik Destek**
```
"Ders notları nasıl paylaşılır?"
"Sertifika nasıl alınır?"
"Staj imkanları var mı?"
```

#### **🔧 Teknik Destek**
```
"Uygulama çalışmıyor"
"Bildirim alamıyorum"
"Şifremi unuttum"
```

#### **📊 Görsel Analiz**
- Ekonomi grafikleri açıklama
- Ders notu içeriği analizi
- Etkinlik posterlerini değerlendirme
- Finansal tabloları yorumlama

### 🎯 AI Asistan Avantajları

- **7/24 Erişilebilirlik**: Her zaman aktif destek
- **Anında Yanıt**: Hızlı ve doğru bilgi
- **Kişiselleştirilmiş**: Kullanıcı adıyla özel karşılama
- **Çok Dilli**: Türkçe odaklı doğal dil işleme
- **Öğrenebilir**: Sürekli gelişen bilgi bankası

## 🔮 Gelecek Planları

### Yakın Dönem
- iOS desteği genişletme
- Çevrimdışı mod iyileştirmeleri
- Daha fazla dil desteği
- Gelişmiş analitik

### Uzun Dönem
- Web uygulaması geliştirme(Web sitesi muhtemelen aynı kalıcak bir süre daha)
- **Yapay zeka entegrasyonu** ✅ **TAMAMLANDI**
- Sosyal özellikler genişletme
- Mikroservis mimarisi

## 📱 Uygulama Ekran Görüntüleri

<div align="center">
  <img src="https://r.resimlink.com/0BKyUzkbDhF.jpg" width="200"/>
  <img src="https://r.resimlink.com/mdVa90Y5_kc.jpg" width="200"/>
  <img src="https://r.resimlink.com/g0Dn6Hj7NR.jpg" width="200"/>
  <img src="https://r.resimlink.com/rZ5HXtwTLyi.jpg" width="200"/>
</div>

<div align="center">
  <img src="https://r.resimlink.com/6lVfg.jpg" width="200"/>
  <img src="https://r.resimlink.com/O_Fg0hs1.jpg" width="200"/>
  <img src="https://r.resimlink.com/tsz-JqXNA.jpg" width="200"/>
  <img src="https://r.resimlink.com/IFEgL.jpg" width="200"/>
</div>

<div align="center">
  <img src="https://r.resimlink.com/JL7fY61ykD3.jpg" width="200"/>
  <img src="https://r.resimlink.com/oxU_JkX7prD.jpg" width="200"/>
  <img src="https://r.resimlink.com/_zPQaNC.jpg" width="200"/>
  <img src="https://r.resimlink.com/E9PVRF.jpg" width="200"/>
</div>

<div align="center">
  <img src="https://r.resimlink.com/3md5lyQ6MFYL.jpg" width="200"/>
  <img src="https://r.resimlink.com/H72bxAdM.jpg" width="200"/>
  <img src="https://r.resimlink.com/_JiWaSqXU.jpg" width="200"/>
  <img src="https://r.resimlink.com/h7dALa4jn8mq.jpg" width="200"/>
</div>

<div align="center">
  <img src="https://r.resimlink.com/rik1c3NL-O.jpg" width="200"/>
  <img src="https://r.resimlink.com/EVcydXAKSlg.jpg" width="200"/>
  <img src="https://r.resimlink.com/X4j8V03mwNR.jpg" width="200"/>
  <img src="https://r.resimlink.com/GOwZu.jpg" width="200"/>
</div>

## 🎬 Medya ve Kaynaklar

### 📺 Video İçerikleri
- **[Proje Tanıtım Videosu](https://www.youtube.com/watch?v=3jnqW75B0Bk)** - KET mobil uygulaması ve web sitesinin kapsamlı tanıtımı
- **Özellik Demoları** - Uygulamanın temel özelliklerinin gösterimi
- **Kurulum Rehberi** - Adım adım kurulum ve yapılandırma

### 📚 Dokümantasyon
- **API Dokümantasyonu** - Firebase ve harici API entegrasyonları
- **Geliştirici Rehberi** - Kod yapısı ve geliştirme standartları
- **Kullanıcı Kılavuzu** - Uygulama kullanım rehberi

---

**Not**: Bu README dosyası sürekli güncellenmektedir. En güncel bilgiler için repository'yi takip edin.

<div align="center">
  <strong>KET ile ekonomi dünyasında bir adım önde olun! 📈</strong>
  <br><br>
  <img src="https://img.shields.io/badge/Flutter-3.6.1+-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.6.1+-blue?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Firebase-Latest-orange?logo=firebase" alt="Firebase">
  <img src="https://img.shields.io/badge/Version-6.8.9-green" alt="Version">
  <br>
  <a href="https://www.youtube.com/watch?v=3jnqW75B0Bk">
    <img src="https://img.shields.io/badge/YouTube-Tanıtım_Videosu-red?logo=youtube" alt="YouTube Video">
  </a>
</div>


