# User Flows

## CircleStream — End-to-End User Journey Maps

---

## 1. Onboarding Flow

```
App Launch
    │
    ▼
Splash Screen (token check)
    │
    ├── Token valid ──────────────────────────────▶ Feed Screen
    │
    └── No token / expired
            │
            ▼
        Welcome Screen
            │
            ├── "Masuk" ──▶ Login Screen
            │                   │
            │                   ├── Success ──▶ Feed Screen
            │                   └── Fail ──▶ Show error, stay
            │
            └── "Daftar" ──▶ Register Screen
                                │
                                ├── Success ──▶ Feed Screen (empty state)
                                └── Fail ──▶ Show error, stay
```

---

## 2. Create Circle Flow

```
Profile Screen
    │
    "Buat Circle Baru"
    │
    ▼
Create Circle Screen
    │
    [Input: nama circle]
    │
    "Buat Circle"
    │
    ├── Loading...
    │
    ├── Success
    │       │
    │       ▼
    │   Bottom Sheet: "Circle Berhasil Dibuat!"
    │       ├── Tampilkan invite code
    │       ├── Button: "Salin Kode"
    │       ├── Button: "Bagikan"
    │       └── Button: "Buka Feed" ──▶ Feed Screen (circle baru, kosong)
    │
    └── Error ──▶ Tampilkan pesan error
```

---

## 3. Join Circle Flow

```
Profile Screen / Welcome State
    │
    "Gabung Circle"
    │
    ▼
Join Circle Screen
    │
    [Input: invite code 8 digit]
    │
    "Gabung"
    │
    ├── Loading...
    │
    ├── Success
    │       │
    │       ▼
    │   Toast: "Berhasil gabung ke [Nama Circle]!"
    │       │
    │       └──▶ Feed Screen (circle yang baru dimasuki)
    │
    └── Error
            ├── code_not_found ──▶ "Kode tidak ditemukan"
            ├── circle_full ──▶ "Circle sudah penuh (10/10)"
            ├── already_member ──▶ "Kamu sudah di circle ini"
            └── code_expired ──▶ "Kode sudah kadaluarsa"
```

---

## 4. Photo Upload Flow (Critical Path)

```
Feed Screen / Bottom Nav Camera Tab
    │
    Tap Camera
    │
    ▼
Camera Capture Screen
    │
    [Arahkan kamera]
    │
    Tap Shutter Button
    │
    ▼
Photo Preview Screen
    │
    ├── "Retake" ──▶ Kembali ke Camera Capture
    │
    └── "Post ke [Circle]"
            │
            ▼
        Step 1: Compress foto
            │ (progress indicator)
            ▼
        Step 2: Request presigned URL (POST /media/presign-upload)
            │
            ▼
        Step 3: Upload ke R2 (PUT langsung)
            │ (progress bar %)
            ▼
        Step 4: Finalize (POST /media/finalize)
            │
            ▼
        Success ──▶ Navigate ke Feed
                        │
                        └── Foto muncul real-time di semua device
```

**Error handling:**
- Compress gagal → retry atau cancel
- Presign gagal → tampilkan error, retry
- Upload R2 gagal → retry (tidak perlu presign ulang jika belum expired)
- Finalize gagal → retry finalize saja (file sudah di R2)

---

## 5. Reaction Flow

```
Feed Screen (melihat foto)
    │
    Tap / hold emoji
    │
    ▼
POST /posts/:id/reactions {emoji: "❤️"}
    │
    ├── Success
    │       │
    │       ├── Local: update count langsung (optimistic)
    │       └── Ably event diterima semua device
    │               │
    │               └── Floating emoji animation naik di semua device
    │
    └── Error ──▶ Revert optimistic update
```

---

## 6. Real-time Feed Update Flow

```
Device A (poster)          Backend              Device B, C, D (viewers)
    │                         │                         │
    │── upload flow ─────────▶│                         │
    │                         │── publish post_created ─▶│
    │◀── navigate to feed     │                         │
    │                         │                 ├── Ably event received
    │                         │                 ├── New post card muncul di atas
    │                         │                 └── Animasi slide down
```

---

## 7. Leave Circle Flow

```
Circle Detail Screen
    │
    "Keluar dari Circle"
    │
    ▼
Confirmation Dialog
    │
    ├── Batal ──▶ Tutup dialog
    │
    └── Ya, Keluar
            │
            ▼
        POST /circles/:id/leave
            │
            ├── Success ──▶ Navigate ke Circle List / Feed (circle lain)
            │
            └── Error: owner_cannot_leave
                    │
                    └── Dialog: "Kamu adalah owner. Transfer atau hapus circle dulu."
```

---

## 8. Token Refresh Flow (Background)

```
Any API Request
    │
    ├── Response 401
    │       │
    │       ▼
    │   POST /auth/refresh (dengan refresh token)
    │       │
    │       ├── Success ──▶ Simpan access token baru ──▶ Retry request
    │       │
    │       └── Fail (refresh expired) ──▶ Logout ──▶ Welcome Screen
    │
    └── Response OK ──▶ Proses normal
```

Implementasi dengan Dio interceptor:

```dart
class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await authService.refreshToken();
      if (refreshed) {
        // Retry original request
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer ${authService.accessToken}';
        final response = await dio.fetch(opts);
        return handler.resolve(response);
      } else {
        authBloc.add(LogoutEvent());
      }
    }
    handler.next(err);
  }
}
```
