# Product Requirements Document (PRD)

## CircleStream MVP

---

## 1. Overview

CircleStream MVP adalah versi pertama yang mencakup fitur inti: auth, circle management, photo upload, real-time feed, dan emoji reaction.

---

## 2. User Stories

### Auth
- Sebagai user baru, saya bisa register dengan username, email, dan password
- Sebagai user, saya bisa login dan mendapat JWT token
- Sebagai user, saya bisa logout dan invalidate token
- Sebagai user, saya bisa refresh access token tanpa re-login

### Circle
- Sebagai user, saya bisa membuat circle baru dengan nama
- Sebagai user, saya mendapat invite code saat membuat circle
- Sebagai user, saya bisa join circle menggunakan invite code
- Sebagai user, saya bisa melihat daftar member di circle saya
- Sebagai user, saya bisa leave circle kapan saja
- Sebagai owner, saya bisa generate ulang invite code

### Upload & Feed
- Sebagai member circle, saya bisa mengambil foto dari kamera dan mengupload ke circle
- Sebagai member circle, saya bisa melihat semua foto di circle secara kronologis
- Sebagai member circle, saya melihat foto baru muncul real-time tanpa refresh
- Sebagai member circle, saya bisa load foto lama dengan scroll (pagination)

### Reaction
- Sebagai member circle, saya bisa memberi emoji reaction ke sebuah foto
- Sebagai member circle, saya melihat jumlah reaction per emoji di setiap foto
- Sebagai member circle, saya melihat animasi emoji floating saat seseorang bereaksi
- Semua reaction update terjadi real-time

---

## 3. Functional Requirements

### FR-AUTH-01: Registration
- Input: username, email, password
- Validasi: email unik, password minimal 8 karakter
- Output: user created, JWT access + refresh token

### FR-AUTH-02: Login
- Input: email, password
- Validasi: credentials cocok
- Output: JWT access + refresh token

### FR-AUTH-03: Token Refresh
- Input: refresh token
- Output: access token baru

### FR-AUTH-04: Logout
- Invalidate refresh token di server

### FR-CIRCLE-01: Create Circle
- Input: name
- Validasi: user harus sudah login
- Output: circle dibuat, user jadi owner, invite code di-generate

### FR-CIRCLE-02: Join Circle
- Input: invite code
- Validasi: code valid, circle belum penuh (max 10), user belum join
- Output: user ditambah sebagai member

### FR-CIRCLE-03: Leave Circle
- Owner tidak bisa leave sebelum transfer ownership atau delete circle
- Member biasa bisa leave kapan saja

### FR-UPLOAD-01: Presign Upload
- Backend generate presigned URL untuk R2
- URL expires dalam 15 menit
- Hanya member circle yang bisa request

### FR-UPLOAD-02: Finalize Upload
- Setelah upload ke R2, Flutter kirim metadata ke backend
- Backend simpan ke Turso
- Backend publish event ke Ably

### FR-FEED-01: Load Feed
- Default: 20 foto terbaru
- Pagination dengan cursor (created_at)
- Hanya member circle yang bisa akses

### FR-REACTION-01: Add Reaction
- Input: post_id, emoji (dari preset)
- Counter di-increment di Redis
- Event dikirim ke Ably

### FR-REACTION-02: Reaction Presets
Emoji yang diizinkan:
```
❤️ 😂 😮 🔥 👏 😢 🤩 💀
```

---

## 4. Non-Functional Requirements

### NFR-PERF-01: Real-time Latency
- Reaction update harus muncul < 500ms setelah dikirim

### NFR-PERF-02: Feed Load
- Feed pertama harus load < 2 detik

### NFR-SEC-01: Privacy
- User tidak bisa mengakses circle yang bukan miliknya
- Semua endpoint sensitif wajib JWT

### NFR-SCALE-01: Backend Stateless
- Backend tidak menyimpan state sesi
- Semua state di Turso / Redis

### NFR-IMG-01: Image Format
- Format yang didukung: JPG, JPEG, PNG, WEBP
- Max upload raw: 10 MB
- Target setelah kompresi: ≤ 3 MB
- Flutter wajib compress sebelum upload

---

## 5. Out of Scope (MVP)

- Caption panjang
- Komentar teks
- Like tradisional
- Upload dari galeri
- Story / ephemeral content
- Push notification
- Dark mode
- Video
- Multiple photo per post
- Search
- Block / report user

---

## 6. Acceptance Criteria

| Fitur | Kriteria |
|---|---|
| Register | User bisa register dan langsung login |
| Login | JWT diterima, akses ke endpoint protected |
| Create Circle | Circle dibuat, invite code ada |
| Join Circle | User jadi member, muncul di member list |
| Upload | Foto tersimpan di R2, metadata di Turso |
| Feed | Foto muncul real-time di semua device dalam circle |
| Reaction | Count update real-time, animasi floating muncul |
