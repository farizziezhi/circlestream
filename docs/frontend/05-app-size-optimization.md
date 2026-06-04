# App Size Optimization

## CircleStream — Flutter Build Size Guide

---

## 1. Target Size

| Platform | Target | Prioritas |
|---|---|---|
| Android APK (universal) | ≤ 25 MB | Utama |
| Android App Bundle | ≤ 15 MB (per device) | Utama |
| iOS IPA | ≤ 30 MB | Sekunder |

Android adalah prioritas utama. iOS tetap di-support tapi tidak jadi fokus optimasi.

---

## 2. Android — Prioritas Utama

### 2.1 Gunakan App Bundle, Bukan APK

App Bundle memungkinkan Google Play (atau distribusi manual) hanya mengirim arsitektur yang dibutuhkan device user.

```bash
# Jangan pakai ini untuk release
flutter build apk --release

# Pakai ini
flutter build appbundle --release

# Atau kalau mau APK langsung (untuk demo/portfolio tanpa Play Store)
# Split per ABI — jauh lebih kecil dari universal APK
flutter build apk --split-per-abi --release
```

Split per ABI menghasilkan 3 file terpisah:
```
build/app/outputs/flutter-apk/
├── app-arm64-v8a-release.apk    ← device modern (2018+), pakai ini untuk demo
├── app-armeabi-v7a-release.apk  ← device lama
└── app-x86_64-release.apk       ← emulator
```

Untuk portfolio demo, cukup bagikan `app-arm64-v8a-release.apk`.

---

### 2.2 Enable R8 / ProGuard (Shrinking & Obfuscation)

File: `android/app/build.gradle`

```gradle
android {
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true          // ← aktifkan R8
            shrinkResources true        // ← hapus resource yang tidak dipakai
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                         'proguard-rules.pro'
        }
    }
}
```

File: `android/app/proguard-rules.pro`

```
# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Ably
-keep class io.ably.** { *; }

# Keep model classes dari JSON parsing
-keep class com.circlestream.** { *; }

# Gson (jika dipakai)
-keepattributes Signature
-keepattributes *Annotation*
```

---

### 2.3 Flutter Build Flags

```bash
# Full optimized release build
flutter build apk \
  --split-per-abi \
  --release \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --dart-define=API_BASE_URL=https://api.circlestream.app/v1

# --obfuscate          : obfuscate Dart code (kecilkan ukuran + keamanan)
# --split-debug-info   : pisahkan debug symbols (wajib jika pakai --obfuscate)
```

---

### 2.4 Analyze APK Size

```bash
# Setelah build, analyze ukuran
flutter build apk --analyze-size --release

# Atau gunakan Android Studio
# Build → Analyze APK → pilih file .apk
```

---

## 3. Font Optimization

DM Sans + Poppins kalau di-bundle penuh bisa 2-3 MB sendiri. Cukup include weight yang dipakai.

### pubspec.yaml — Font Subsetting

```yaml
flutter:
  fonts:
    - family: DMSans
      fonts:
        - asset: assets/fonts/DMSans-Regular.ttf    # weight 400
          weight: 400
        - asset: assets/fonts/DMSans-Medium.ttf     # weight 500
          weight: 500
        # JANGAN include weight yang tidak dipakai (Light, Thin, ExtraBold, dll)

    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-SemiBold.ttf  # weight 600, untuk heading
          weight: 600
        # Poppins hanya untuk heading — tidak perlu semua weight
```

Atau gunakan `google_fonts` package dengan download on-demand (tidak di-bundle):

```dart
// Di main.dart — cache font saat pertama launch
GoogleFonts.config.allowRuntimeFetching = true;

// Pakai di theme
TextStyle(fontFamily: GoogleFonts.dmSans().fontFamily)
```

Tapi ini butuh internet saat pertama buka — untuk portfolio demo yang offline, lebih aman bundle manual.

---

## 4. Image & Asset Optimization

### 4.1 Gunakan WebP untuk Semua Asset UI

```bash
# Install cwebp (macOS)
brew install webp

# Convert PNG ke WebP
cwebp -q 90 assets/images/logo.png -o assets/images/logo.webp
cwebp -q 90 assets/images/welcome_bg.png -o assets/images/welcome_bg.webp
```

Update reference di kode:
```dart
Image.asset('assets/images/logo.webp')
```

### 4.2 Gunakan Ukuran yang Tepat

Flutter butuh 3 resolusi untuk asset:
```
assets/images/logo.webp          ← 1x (base)
assets/images/2.0x/logo.webp    ← 2x
assets/images/3.0x/logo.webp    ← 3x
```

Untuk CircleStream yang UI-nya minimalis, gambar dekoratif seharusnya sangat sedikit — sebagian besar UI adalah widget Flutter, bukan asset gambar.

### 4.3 Hapus Asset yang Tidak Dipakai

```bash
# Cari asset yang tidak direferensikan di kode
grep -r "assets/" lib/ | grep -oP "assets/[^'\"]*" | sort | uniq > used_assets.txt
ls assets/ >> all_assets.txt
# Bandingkan keduanya
```

---

## 5. Dependency Audit

Beberapa package CircleStream yang perlu diperhatikan:

```yaml
dependencies:
  # ✅ Ringan
  equatable: ^2.0.5           # pure Dart, kecil
  uuid: ^4.3.3                # pure Dart, kecil
  go_router: ^13.0.0          # ringan
  
  # ⚠️ Sedang — perlu dikonfigurasi
  dio: ^5.4.0                 # OK, tapi jangan import semua interceptor
  flutter_bloc: ^8.1.3        # OK
  cached_network_image: ^3.3.1 # OK tapi bawa banyak dependency
  
  # ⚠️ Berat — native code
  camera: ^0.10.5+9           # bawa native camera library, tidak bisa dihindari
  ably_flutter: ^1.2.23       # bawa native Ably SDK, tidak bisa dihindari
  flutter_image_compress: ^2.1.0 # native, tapi worth it karena fungsional penting
  
  # ✅ Ganti kalau bisa
  # Hindari package yang bawa Firebase kalau tidak perlu
  # Hindari multiple HTTP client (pilih Dio ATAU http, jangan dua-duanya)
```

**Audit command:**

```bash
# Lihat semua dependency tree
flutter pub deps

# Cek ukuran contribution tiap package
flutter build apk --analyze-size --release
# Lalu buka build/flutter_size_analysis.json
```

---

## 6. Deferred Loading (Dart)

Load screen yang jarang dibuka secara lazy — tidak ikut di-bundle di initial load.

```dart
// Contoh: InviteCodeScreen jarang dibuka, defer loadingnya
import 'package:circlestream/features/circle/screens/invite_code_screen.dart'
    deferred as inviteScreen;

// Di router, load saat dibutuhkan
Future<void> loadInviteScreen() async {
  await inviteScreen.loadLibrary();
  // Baru navigate
}
```

**Screen yang cocok untuk deferred loading di CircleStream:**
- `InviteCodeScreen`
- `CircleMembersScreen`
- `CreateCircleScreen`

**Screen yang JANGAN di-defer** (sering diakses):
- `FeedScreen`
- `CameraCaptureScreen`
- `LoginScreen`

---

## 7. Mengurangi Ukuran Icon

### Gunakan icon font bukan PNG

CircleStream sudah menggunakan Material Icons (built-in Flutter) — ini sudah optimal. Jangan tambah icon library eksternal seperti FontAwesome kecuali sangat dibutuhkan.

### Tree-shake icon

Flutter otomatis tree-shake icons yang tidak dipakai sejak Flutter 2.x. Pastikan tidak import `Icons.*` yang tidak terpakai.

---

## 8. iOS — Tips Sekunder

Meskipun bukan prioritas utama, beberapa hal yang otomatis terhandle:

```bash
# Build iOS release
flutter build ios --release

# Build IPA (butuh Apple Developer account)
flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/debug-info
```

iOS otomatis melakukan:
- Bitcode stripping
- Symbol stripping di release build
- App Thinning (hanya kirim slice yang sesuai device)

Untuk portfolio demo iOS, gunakan **Simulator** atau **TestFlight** (butuh Apple Developer $99/tahun).

---

## 9. Build Script (Makefile)

Tambahkan ke `Makefile` di root Flutter project:

```makefile
.PHONY: build-android build-android-apk build-ios analyze-size

# Android App Bundle (untuk Play Store)
build-android:
	flutter build appbundle \
		--release \
		--obfuscate \
		--split-debug-info=build/debug-info \
		--dart-define=API_BASE_URL=https://api.circlestream.app/v1

# Android APK split per ABI (untuk demo/portfolio)
build-android-apk:
	flutter build apk \
		--split-per-abi \
		--release \
		--obfuscate \
		--split-debug-info=build/debug-info \
		--dart-define=API_BASE_URL=https://api.circlestream.app/v1
	@echo "APK files:"
	@ls -lh build/app/outputs/flutter-apk/*.apk

# iOS (butuh Mac + Xcode)
build-ios:
	flutter build ipa \
		--release \
		--obfuscate \
		--split-debug-info=build/debug-info \
		--dart-define=API_BASE_URL=https://api.circlestream.app/v1

# Analyze APK size
analyze-size:
	flutter build apk --analyze-size --release
	@echo "Check build/flutter_size_analysis.json"
```

---

## 10. Checklist Sebelum Release

- [ ] Build menggunakan `--split-per-abi` (bukan universal APK)
- [ ] `minifyEnabled true` dan `shrinkResources true` di build.gradle
- [ ] Font hanya include weight yang dipakai
- [ ] Semua asset UI sudah WebP
- [ ] Tidak ada package duplikat (dua HTTP client, dua image loader, dll)
- [ ] `--obfuscate` dan `--split-debug-info` aktif
- [ ] Run `flutter build apk --analyze-size` dan cek hasilnya
- [ ] Test APK arm64 di device fisik Android sebelum distribusi
