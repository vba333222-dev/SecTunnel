# 📱 MANUAL GUIDE PBROWSER

**Versi:** 1.0.0  
**Platform:** Android  
**Bahasa:** Indonesia  

---

## 📖 Daftar Isi

1. [Tentang Aplikasi](#-tentang-aplikasi)
2. [Fitur Utama](#-fitur-utama)
3. [Persyaratan Sistem](#-persyaratan-sistem)
4. [Instalasi](#-instalasi)
5. [Cara Menggunakan](#-cara-menggunakan)
6. [Konfigurasi Proxy](#-konfigurasi-proxy)
7. [Troubleshooting](#-troubleshooting)
8. [FAQ](#-faq)
9. [Untuk Developer](#-untuk-developer)

---

## 🎯 Tentang Aplikasi

**PBrowser** adalah aplikasi browser Android yang dibangun dengan Flutter, dirancang khusus untuk memberikan pengalaman browsing yang aman dan terenkripsi melalui koneksi proxy. Aplikasi ini menyediakan:

- ✅ **Koneksi Terenkripsi**: Semua traffic internet dialihkan melalui proxy aman
- ✅ **Bypass Otomatis**: Domain khusus dapat mengakses internet secara langsung
- ✅ **SSL Bypass**: Menangani sertifikat SSL secara otomatis
- ✅ **UI Modern**: Antarmuka yang clean dan mudah digunakan
- ✅ **Lightweight**: Aplikasi ringan dan cepat

---

## ⚡ Fitur Utama

### 1. **Proxy Otomatis**
- Semua koneksi internet secara otomatis menggunakan proxy server
- IP Address Proxy: `72.62.122.59:59312`
- Enkripsi penuh untuk keamanan data

### 2. **Domain Bypass**
- Domain tertentu dapat mengakses internet tanpa proxy
- Konfigurasi default:
  - `*.workers.dev`
  - `*.job-anggaajie.*`

### 3. **Tunnel Activation**
- Verifikasi koneksi otomatis saat aplikasi dibuka
- URL Aktivasi: `https://secureverify.job-anggaajie.workers.dev/`
- Retry otomatis jika koneksi gagal

### 4. **Browser Lengkap**
- Address bar dengan auto-complete
- Tombol navigasi (Back, Refresh)
- Progress indicator untuk loading halaman
- JavaScript support penuh
- Media playback tanpa user gesture

---

## 💻 Persyaratan Sistem

### Hardware Minimum
- **RAM**: 2 GB (4 GB direkomendasikan)
- **Storage**: 50 MB ruang kosong
- **Processor**: ARMv7 atau lebih tinggi

### Software
- **OS**: Android 5.0 (Lollipop) atau lebih baru
- **Android SDK**: API Level 21+
- **Koneksi Internet**: Diperlukan untuk semua operasi

---

## 📥 Instalasi

### A. Instalasi APK (Pengguna)

1. **Download APK**
   - Dapatkan file `pbrowser-release.apk` dari developer
   - Simpan di folder Downloads atau lokasi yang mudah diakses

2. **Enable Unknown Sources**
   - Buka **Settings** → **Security**
   - Aktifkan **"Install from Unknown Sources"** atau **"Allow from this source"**
   
3. **Install APK**
   - Buka file manager, cari file APK
   - Tap file APK → Tap **Install**
   - Tunggu proses instalasi selesai
   - Tap **Open** untuk menjalankan aplikasi

4. **Verifikasi Instalasi**
   - Aplikasi akan muncul di app drawer dengan nama "PBrowser"
   - Icon: Default Flutter blue icon

### B. Build dari Source Code (Developer)

Lihat bagian [Untuk Developer](#-untuk-developer) di bawah.

---

## 🚀 Cara Menggunakan

### Pertama Kali Membuka Aplikasi

1. **Launch PBrowser**
   - Tap icon PBrowser di home screen atau app drawer

2. **Splash Screen - Tunnel Activation**
   ```
   Securing Tunnel...
   ```
   - Aplikasi akan melakukan verifikasi koneksi ke server aktivasi
   - Proses ini biasanya memakan waktu 2-5 detik
   - Jika berhasil, akan muncul pesan:
   ```
   Tunnel Established. Launching...
   ```

3. **Browser Screen Terbuka**
   - Setelah tunnel aktif, browser akan otomatis terbuka
   - Halaman default: `https://whoer.net/ip`
   - Gunakan halaman ini untuk memverifikasi IP proxy Anda

### Navigasi di Browser

#### 📍 Address Bar (URL Bar)
```
┌─────────────────────────────────────────┐
│ 🔒 Search or enter URL              🔄  │
└─────────────────────────────────────────┘
```

**Cara Menggunakan:**
1. Tap pada address bar
2. Ketik URL lengkap atau keyword pencarian
   - Contoh URL: `https://google.com`
   - Jika tidak ada `http://` atau `https://`, aplikasi otomatis menambahkan `https://`
3. Tap **Enter** atau tombol **Go** di keyboard
4. Halaman akan dimuat dengan proxy aktif

#### ⬅️ Tombol Back
- **Fungsi**: Kembali ke halaman sebelumnya
- **Lokasi**: Pojok kiri atas
- **Aktif**: Hanya jika ada history halaman

#### 🔄 Tombol Refresh
- **Fungsi**: Reload halaman saat ini
- **Lokasi**: Pojok kanan atas
- **Shortcut**: Tap untuk reload paksa

#### 📊 Progress Bar
- Muncul di bawah AppBar saat halaman loading
- Warna biru, mengindikasikan progress loading (0-100%)

### Tips Browsing

1. **Cek IP Proxy**
   - Kunjungi `https://whoer.net/ip`
   - Atau `https://ipinfo.io`
   - Verifikasi IP berubah ke IP proxy: `72.62.122.59`

2. **Akses Website Terblokir**
   - Semua website otomatis diakses via proxy
   - Tidak perlu konfigurasi manual

3. **Media & JavaScript**
   - Otomatis aktif untuk semua website
   - Video, audio, dan iframe support penuh

---

## 🔧 Konfigurasi Proxy

### Informasi Proxy Default

```yaml
Proxy Server: 72.62.122.59
Port: 59312
Protocol: HTTP/HTTPS Proxy
Authentication: None
```

### Domain Bypass List

Domain berikut **TIDAK menggunakan proxy** (akses langsung):

1. `*.workers.dev` - Cloudflare Workers
2. `job-anggaajie.workers.dev` - Server aktivasi
3. Domain lain yang mengandung `job-anggaajie`

### Mengubah Konfigurasi Proxy

> ⚠️ **PERINGATAN**: Hanya untuk advanced users!

Jika Anda perlu mengubah proxy server:

1. Edit file: `lib/main.dart`
2. Cari baris:
   ```dart
   const proxy = "PROXY 72.62.122.59:59312;";
   ```
3. Ganti dengan proxy baru:
   ```dart
   const proxy = "PROXY [IP_BARU]:[PORT_BARU];";
   ```
4. Rebuild APK (lihat bagian Developer)

### Menambah Domain Bypass

1. Edit file: `lib/main.dart`
2. Cari fungsi `findProxy`:
   ```dart
   if (uri.host.contains('workers.dev') || uri.host.contains('job-anggaajie')) {
     return "DIRECT";
   }
   ```
3. Tambahkan kondisi baru:
   ```dart
   if (uri.host.contains('workers.dev') || 
       uri.host.contains('job-anggaajie') ||
       uri.host.contains('example.com')) {  // Domain baru
     return "DIRECT";
   }
   ```
4. Rebuild APK

---

## 🔍 Troubleshooting

### Problem 1: "Retrying Connection..." Loop

**Gejala:**
```
Retrying Connection...
Retrying Connection...
Retrying Connection...
```
Aplikasi stuck di splash screen.

**Penyebab:**
- Server aktivasi tidak bisa diakses
- Koneksi internet bermasalah
- Firewall memblokir aplikasi

**Solusi:**
1. Cek koneksi internet Anda
2. Pastikan tidak ada VPN yang aktif
3. Cek status firewall/antivirus
4. Tunggu 3-5 detik untuk retry otomatis
5. Jika masih gagal, close dan re-open aplikasi
6. Restart perangkat jika perlu

---

### Problem 2: Website Tidak Bisa Dibuka

**Gejala:**
- Blank page atau error page
- "ERR_CONNECTION_REFUSED"
- "ERR_PROXY_CONNECTION_FAILED"

**Penyebab:**
- Proxy server down atau tidak merespon
- Website memblokir proxy
- SSL certificate error

**Solusi:**
1. **Cek proxy server**
   ```
   Pastikan proxy 72.62.122.59:59312 masih aktif
   ```
2. **Test website lain**
   - Coba akses `http://example.com`
   - Jika berhasil, berarti website spesifik yang bermasalah
3. **Clear cache**
   - Settings → Apps → PBrowser → Storage → Clear Cache
4. **Reinstall aplikasi**

---

### Problem 3: Loading Sangat Lambat

**Gejala:**
- Progress bar stuck
- Halaman tidak fully loaded
- Timeout errors

**Penyebab:**
- Proxy server overload
- Bandwidth terbatas
- Website berat

**Solusi:**
1. Tunggu beberapa saat (proxy dapat lebih lambat dari direct connection)
2. Refresh halaman dengan tombol reload
3. Coba website lebih ringan terlebih dahulu
4. Cek kecepatan internet Anda
5. Restart aplikasi

---

### Problem 4: Address Bar Tidak Berfungsi

**Gejala:**
- Tidak bisa ketik di URL bar
- Keyboard tidak muncul
- Enter tidak meload halaman

**Solusi:**
1. Tap kembali pada address bar
2. Close keyboard dan buka kembali
3. Coba tap tombol refresh terlebih dahulu
4. Restart aplikasi jika masih bermasalah

---

### Problem 5: Aplikasi Crash/Force Close

**Gejala:**
- "PBrowser has stopped"
- Aplikasi tiba-tiba tertutup
- Blank screen

**Solusi:**
1. **Clear App Data**
   - Settings → Apps → PBrowser → Storage → Clear Data
2. **Reinstall Aplikasi**
   - Uninstall PBrowser
   - Install ulang APK terbaru
3. **Check Android Version**
   - Minimal Android 5.0 required
4. **Free up RAM**
   - Close aplikasi lain yang berjalan di background

---

### Problem 6: SSL/HTTPS Error

**Gejala:**
- "Your connection is not private"
- "NET::ERR_CERT_INVALID"

**Penyebab:**
- SSL bypass tidak berfungsi
- Website menggunakan certificate pinning

**Solusi:**
1. Aplikasi sudah handle SSL bypass otomatis
2. Jika tetap error, website mungkin tidak kompatibel dengan proxy
3. Coba akses versi HTTP (bukan HTTPS) jika tersedia

---

## ❓ FAQ

### Q1: Apakah data saya aman?
**A:** Ya, semua traffic dialihkan melalui proxy server yang sudah dikonfigurasi. Namun, keamanan juga bergantung pada proxy server yang Anda gunakan. Gunakan proxy terpercaya.

### Q2: Apakah semua website bisa diakses?
**A:** Ya, namun beberapa website dengan security tinggi (banking, payment gateway) mungkin memblokir koneksi dari proxy. Ini adalah mekanisme keamanan normal.

### Q3: Kenapa tidak bisa download file?
**A:** Download file masih dalam development. Saat ini aplikasi fokus pada browsing website.

### Q4: Apakah bisa ganti proxy server?
**A:** Ya, tapi butuh rebuild aplikasi. Lihat bagian [Konfigurasi Proxy](#-konfigurasi-proxy).

### Q5: Apakah ada versi iOS?
**A:** Saat ini hanya tersedia untuk Android. Versi iOS bisa dikembangkan dengan kode yang sama (Flutter cross-platform).

### Q6: Berapa konsumsi data?
**A:** Sama dengan browsing normal, namun mungkin sedikit lebih tinggi karena overhead proxy connection.

### Q7: Apakah legal menggunakan proxy?
**A:** Legal, selama tidak digunakan untuk aktivitas ilegal. Gunakan dengan bijak dan ikuti hukum setempat.

### Q8: Kenapa IP saya berubah?
**A:** Itu adalah fungsi utama aplikasi - mengubah IP Anda ke IP proxy server untuk privacy dan bypass restriction.

---

## 👨‍💻 Untuk Developer

### Build APK dari Source

#### Prasyarat
```bash
- Flutter SDK (versi 3.0.0+)
- Android Studio atau VS Code
- Android SDK (API Level 21+)
- JDK 11 atau lebih tinggi
```

#### Langkah-langkah

1. **Clone/Download Project**
   ```bash
   cd c:\Users\USER\Documents\pbrowser
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify Configuration**
   - Cek `android/app/build.gradle`
   - Cek `android/gradle.properties`
   - Cek signing configuration jika ada

4. **Build Debug APK**
   ```bash
   flutter build apk --debug
   ```
   Output: `build/app/outputs/flutter-apk/app-debug.apk`

5. **Build Release APK**
   ```bash
   flutter build apk --release
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`

6. **Build Split APK (Recommended)**
   ```bash
   flutter build apk --split-per-abi --release
   ```
   Output: Multiple APKs per architecture (arm64-v8a, armeabi-v7a, x86_64)

### Build untuk Testing

```bash
flutter run --release
```

### Clean Build

Jika ada error saat build:
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Struktur Kode

```
pbrowser/
├── lib/
│   └── main.dart              # Entry point & semua logika
├── android/                   # Android-specific config
│   ├── app/
│   │   ├── build.gradle       # Build configuration
│   │   └── src/main/
│   │       └── AndroidManifest.xml
│   ├── gradle.properties      # Gradle settings
│   └── settings.gradle
├── pubspec.yaml               # Dependencies
└── MANUAL_GUIDE.md           # Dokumentasi ini
```

### Arsitektur Aplikasi

```
main.dart Components:
┌─────────────────────────────┐
│  MyHttpOverrides            │ → Proxy & SSL Configuration
│  - findProxy()              │ → Route traffic to proxy
│  - badCertificateCallback() │ → Bypass SSL errors
└─────────────────────────────┘
           ↓
┌─────────────────────────────┐
│  SplashScreen               │ → Activation Screen
│  - _startBackgroundSync()   │ → Validate connection
│  - _handleError()           │ → Retry logic
└─────────────────────────────┘
           ↓
┌─────────────────────────────┐
│  BrowserScreen              │ → Main Browser UI
│  - WebViewController        │ → Handle WebView
│  - NavigationDelegate       │ → Page events
│  - Platform Optimizations   │ → Android-specific
└─────────────────────────────┘
```

### Kustomisasi

#### 1. Ganti Initial URL
Edit `lib/main.dart` line 186:
```dart
static const String _initialUrl = 'https://whoer.net/ip';
// Ganti dengan URL lain
```

#### 2. Ganti User Agent
Edit `lib/main.dart` line 181-184:
```dart
static const String _userAgent = 
    "Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/120.0.6099.43 Mobile Safari/537.36";
```

#### 3. Ganti Activation URL
Edit `lib/main.dart` line 94:
```dart
const activationUrl = 'https://secureverify.job-anggaajie.workers.dev/';
```

#### 4. Custom Branding
- Ganti app name di `android/app/src/main/AndroidManifest.xml`
- Ganti app icon di `android/app/src/main/res/`
- Ganti theme di `lib/main.dart` (ThemeData)

### Dependencies

```yaml
webview_flutter: ^4.9.0         # Core WebView
webview_flutter_android: ^4.10.0 # Android optimizations
webview_flutter_wkwebview: ^3.13.0 # iOS support
http: ^1.1.0                     # HTTP requests
```

### Debugging

#### Enable Debug Logs
Logcat akan menampilkan:
```
DEBUG: Direct connection for workers.dev
DEBUG: Proxying google.com via PROXY 72.62.122.59:59312;
DEBUG: Sending Activation Request to https://...
DEBUG: Activation Response Code: 200
DEBUG: WebView Error: ...
```

#### View Logs
```bash
flutter logs
# atau
adb logcat | grep DEBUG
```

---

## 📝 Changelog

### Version 1.0.0 (Current)
- ✅ Initial release
- ✅ Proxy configuration with bypass
- ✅ Full browser UI with navigation
- ✅ SSL bypass handling
- ✅ Tunnel activation system
- ✅ Modern Android user-agent
- ✅ Loading progress indicator

### Planned Features (Future)
- 📌 Download manager
- 📌 Bookmark system
- 📌 History tracking
- 📌 Multiple tabs
- 📌 Incognito mode
- 📌 Custom proxy configuration via UI
- 📌 Dark mode

---

## 📞 Support

### Untuk Pengguna
- Hubungi developer melalui channel yang disediakan
- Report bugs dengan detail lengkap (screenshot, Android version, error message)

### Untuk Developer
- Code issues: Check `build_log.txt` dan `build_debug.log`
- Flutter issues: Run `flutter doctor -v`

---

## 📄 License

Aplikasi ini dikembangkan untuk keperluan pribadi/internal. Penggunaan, distribusi, dan modifikasi sesuai kebijakan developer.

---

## ⚠️ Disclaimer

- Gunakan aplikasi ini dengan bijak dan bertanggung jawab
- Developer tidak bertanggung jawab atas penyalahgunaan aplikasi
- Ikuti hukum dan regulasi setempat terkait penggunaan proxy
- Pastikan proxy server yang digunakan adalah legal dan aman

---

**© 2025 PBrowser - Secure Browser with Embedded Proxy**

*Last Updated: 29 Desember 2025*
