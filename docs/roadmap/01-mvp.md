# MVP Roadmap

## CircleStream v0.1 — Minimum Viable Product

---

## 1. MVP Goal

Deliver a working app where:
- Teman bisa buat circle privat
- Foto bisa diambil dan dibagikan ke circle
- Semua member melihat foto baru secara real-time
- Emoji reaction bisa dikirim dan dilihat real-time

---

## 2. MVP Scope

### ✅ Included

**Auth**
- Register dengan username + email + password
- Login → JWT token
- Logout
- Token refresh otomatis

**Circle**
- Buat circle baru
- Join via invite code
- Lihat list member
- Leave circle

**Upload**
- Kamera langsung (bukan galeri)
- Compress + resize sebelum upload
- Upload ke R2 via presigned URL
- Post muncul di feed

**Feed**
- Daftar foto kronologis
- Pagination (load more)
- Real-time new post (via Ably)
- Thumbnail untuk loading cepat

**Reaction**
- 8 emoji preset
- Counter real-time
- Floating emoji animation

**Real-time Events**
- post_created
- reaction_added
- member_joined
- member_left

---

### ❌ Not in MVP

- Push notification
- Dark mode
- Video
- Gallery upload
- Caption panjang
- Komentar teks
- Delete post
- Edit circle name
- Transfer ownership
- Block / report user
- Multiple circles di satu feed
- Story / ephemeral content
- Search

---

## 3. Sprint Plan (6 Weeks)

### Week 1 — Foundation

**Backend:**
- Project setup (Go, Fiber, Turso)
- Database schema + migrations
- Auth endpoints (register, login, refresh, logout)
- JWT middleware

**Frontend:**
- Project setup (Flutter, BLoC)
- Design system (colors, typography, components)
- Auth screens (welcome, login, register)
- Secure token storage

**Target:** Auth bekerja end-to-end

---

### Week 2 — Circle

**Backend:**
- Circle create/join/leave endpoints
- Invite code generation + validation
- Circle member management
- Circle membership middleware

**Frontend:**
- Circle list screen
- Create circle screen
- Join circle screen
- Circle detail screen

**Target:** User bisa buat dan join circle

---

### Week 3 — Upload

**Backend:**
- R2 client setup
- Presign upload endpoint
- Finalize endpoint (simpan metadata + publish event)
- File validation (type, size)

**Frontend:**
- Camera screen (capture)
- Photo preview screen
- Upload flow (compress → presign → upload → finalize)
- Progress indicator

**Target:** Foto bisa diupload dari kamera ke circle

---

### Week 4 — Feed & Real-time

**Backend:**
- Feed endpoint (dengan pagination cursor)
- Ably setup + publish events
- Ably token endpoint untuk client

**Frontend:**
- Feed screen (photo cards)
- Ably subscription
- Real-time new post
- RealtimeBloc routing events

**Target:** Foto muncul real-time di semua device circle

---

### Week 5 — Reactions

**Backend:**
- Upstash Redis setup
- Add reaction endpoint (increment counter)
- Get reaction counts endpoint
- Feed enriched dengan reaction counts

**Frontend:**
- Emoji reaction bar widget
- Floating emoji animation
- Real-time reaction count update
- Optimistic update

**Target:** Emoji reaction bekerja real-time

---

### Week 6 — Polish & Testing

**Backend:**
- Unit tests untuk semua service
- Integration tests untuk critical handlers
- Security audit
- Error handling cleanup
- Rate limiting

**Frontend:**
- BLoC tests
- Widget tests
- UI polish (animasi, spacing)
- Error state handling
- Offline indicator

**Target:** App siap untuk internal testing / TestFlight / beta

---

## 4. Definition of Done (MVP)

MVP dianggap selesai ketika:

1. ✅ Dua user bisa register dan login
2. ✅ User A bisa buat circle dan bagikan invite code ke User B
3. ✅ User B bisa join circle
4. ✅ User A ambil foto dari kamera dan post ke circle
5. ✅ User B melihat foto tersebut real-time tanpa refresh
6. ✅ User B bisa kasih emoji reaction
7. ✅ User A melihat reaction count update real-time + animasi emoji
8. ✅ App tidak crash dalam flow normal
9. ✅ API response time < 500ms
10. ✅ Berjalan di Android dan iOS

---

## 5. Success Metrics (MVP Phase)

| Metric | Target |
|---|---|
| Internal testers | 5–10 orang |
| Post per hari per circle | ≥ 3 |
| Reaction rate | ≥ 50% post dapat reaction |
| Crash rate | < 2% |
| Feed load time | < 2 detik |
| Real-time latency | < 500ms |
