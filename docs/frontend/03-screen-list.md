# Screen List

## CircleStream — Detailed Screen Specifications

---

## 1. Splash Screen

**File:** `lib/features/auth/screens/splash_screen.dart`

**Layout:**
- Background: `#F7FAFF`
- Center: Logo CircleStream + tagline
- Auto-navigate setelah token check selesai (max 2 detik)

**Logic:**
- Check token di SecureStorage
- Jika valid → navigate to Feed
- Jika invalid/expired → try refresh → navigate ke Welcome

---

## 2. Welcome Screen

**File:** `lib/features/auth/screens/welcome_screen.dart`

**Layout:**
- Full screen background dengan gradient soft
- Logo di atas
- Tagline "Real-Time, Raw, Intimate"
- Button: "Masuk" (primary) + "Daftar" (ghost)
- Animasi logo subtle scale/fade masuk

---

## 3. Login Screen

**File:** `lib/features/auth/screens/login_screen.dart`

**Elements:**
- Back button (kembali ke Welcome)
- Title: "Selamat datang kembali"
- Field: Email
- Field: Password (dengan toggle visibility)
- Button: "Masuk" (primary, full width)
- Link: "Belum punya akun? Daftar"

**State:**
- Loading state saat submit
- Error state (shake animation + pesan error)

---

## 4. Register Screen

**File:** `lib/features/auth/screens/register_screen.dart`

**Elements:**
- Back button
- Title: "Buat akun baru"
- Field: Username
- Field: Email
- Field: Password
- Field: Confirm Password
- Button: "Daftar" (primary, full width)
- Link: "Sudah punya akun? Masuk"

**Validation (realtime):**
- Username: min 3 char, alphanumeric + underscore
- Email: format valid
- Password: min 8 char, strength indicator
- Confirm: harus cocok

---

## 5. Feed Screen

**File:** `lib/features/feed/screens/feed_screen.dart`

**Layout:**
```
┌─────────────────────────┐
│ Circle Selector (chips) │
├─────────────────────────┤
│ Photo Card 1            │
│ [image fullwidth]       │
│ [username] [time]       │
│ [reaction bar]          │
├─────────────────────────┤
│ Photo Card 2            │
│ ...                     │
├─────────────────────────┤
│  ╔═══════════════╗      │
│  ║  Bottom Nav   ║      │
│  ╚═══════════════╝      │
└─────────────────────────┘
```

**Features:**
- Pull-to-refresh
- Infinite scroll (pagination cursor)
- Real-time: post baru muncul di atas tanpa refresh
- Real-time: floating emoji animation saat ada reaction
- Empty state: "Belum ada foto. Jadilah yang pertama!" + camera button
- Circle selector di atas jika user ada di multiple circles

**Photo Card:**
- Image: full width, aspect ratio 4:3 atau auto, rounded bottom corners
- Username + avatar placeholder
- Relative time ("2 menit lalu")
- Reaction bar di bawah gambar

---

## 6. Photo Viewer Screen (Fullscreen)

**File:** `lib/features/feed/screens/photo_viewer_screen.dart`

**Layout:**
- Full screen, background hitam
- Foto full screen (pinch-to-zoom)
- Overlay di bawah: username, waktu, reaction bar
- Swipe down untuk dismiss (like Instagram)
- Floating emoji animation jika ada reaction masuk

---

## 7. Camera Screen (Flow, bukan screen tetap)

**Files:**
- `lib/features/camera/screens/camera_capture_screen.dart`
- `lib/features/camera/screens/photo_preview_screen.dart`

**Camera Capture:**
- Full screen camera viewfinder
- Shutter button besar di bawah tengah
- Switch kamera (front/back) di kanan
- Close button di kiri atas
- Flash toggle
- Guide: "Foto untuk [circle name]"

**Photo Preview:**
- Full screen preview foto yang baru diambil
- Button: "Retake" (ghost) + "Post ke [circle name]" (primary)
- Upload progress indicator
- Tidak ada filter atau editing

**Upload Flow:**
1. Compress foto
2. Request presigned URL
3. Upload ke R2
4. Finalize (simpan metadata)
5. Navigate back ke Feed (foto muncul real-time)

---

## 8. Profile Screen

**File:** `lib/features/profile/screens/profile_screen.dart`

**Layout:**
- Avatar placeholder (initials)
- Username + email
- Daftar circle yang diikuti (card list)
- Button: "Buat Circle Baru"
- Button: "Keluar" (ghost, merah)
- App version di bawah

---

## 9. Circle List Screen

**File:** `lib/features/circle/screens/circle_list_screen.dart`

**Layout:**
- Title: "Circle Saya"
- List circle yang diikuti
- FAB atau button: "Buat Circle" + "Gabung Circle"
- Empty state jika belum join circle apapun

---

## 10. Create Circle Screen

**File:** `lib/features/circle/screens/create_circle_screen.dart`

**Elements:**
- Back button
- Title: "Buat Circle Baru"
- Field: Nama Circle
- Button: "Buat Circle" (primary)

**After success:**
- Tampilkan sheet: "Circle berhasil dibuat!"
- Tampilkan invite code yang bisa disalin / share
- Button: "Buka Feed" + "Bagikan Kode"

---

## 11. Join Circle Screen

**File:** `lib/features/circle/screens/join_circle_screen.dart`

**Elements:**
- Back button
- Title: "Gabung Circle"
- Field: Kode Undangan (uppercase auto)
- Button: "Gabung" (primary)

**After success:**
- Tampilkan nama circle yang berhasil dimasuki
- Navigate ke feed circle tersebut

---

## 12. Circle Detail Screen

**File:** `lib/features/circle/screens/circle_detail_screen.dart`

**Layout:**
- Nama circle + member count
- List menu:
  - Lihat Member
  - Kode Undangan (owner only)
  - Keluar dari Circle (merah, bukan owner)

---

## 13. Circle Members Screen

**File:** `lib/features/circle/screens/circle_members_screen.dart`

**Layout:**
- Title: "Member ([count]/10)"
- List member dengan avatar, username, role badge, join date
- Owner badge untuk owner

---

## 14. Invite Code Screen

**File:** `lib/features/circle/screens/invite_code_screen.dart`

**Layout:** (Owner only)
- Tampilkan kode aktif dalam format besar dan terbaca
- Button: Salin Kode
- Button: Share Kode
- Button: Generate Kode Baru
- Toggle: Single-use / Multi-use
- List kode lama (inactive)
