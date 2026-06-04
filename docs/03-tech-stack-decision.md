# Tech Stack Decision

## CircleStream — Why We Chose This Stack

---

## 1. Frontend: Flutter

**Keputusan:** Flutter (Dart)

**Alasan:**
- Single codebase untuk Android dan iOS
- Performa native-like dengan rendering sendiri
- Ekosistem plugin yang mature untuk kamera, image, dan network
- Hot reload mempercepat development
- Cocok untuk UI custom dengan animasi halus

**Alternatif yang dipertimbangkan:**
- React Native — bridge overhead, performa lebih rendah untuk animasi kompleks
- Native Android/iOS — dua codebase terpisah, biaya lebih tinggi

---

## 2. Backend: Golang + Fiber

**Keputusan:** Golang dengan framework Fiber

**Alasan:**
- Golang sangat ringan dan cepat
- Memory footprint kecil, cocok untuk VPS murah
- Fiber mirip Express.js, learning curve rendah
- Concurrent handling sangat baik (goroutines)
- Statically typed, bug lebih sedikit di production
- Binary tunggal, deployment simple

**Alternatif yang dipertimbangkan:**
- Node.js — lebih lambat, memory lebih besar
- Python FastAPI — lebih lambat, GIL limitation
- Rust — terlalu kompleks untuk MVP

---

## 3. Database: Turso (SQLite Edge)

**Keputusan:** Turso

**Alasan:**
- SQLite di edge, latency sangat rendah
- Free tier yang generous untuk MVP
- Tidak perlu manage infrastructure database
- Schema sederhana cocok untuk SQLite
- Libsql driver tersedia untuk Golang
- Bisa replika ke multiple region

**Alternatif yang dipertimbangkan:**
- PostgreSQL (Supabase) — overkill untuk MVP, biaya lebih tinggi
- MySQL — setup lebih kompleks
- MongoDB — schema-less tidak dibutuhkan di sini
- PlanetScale — MySQL, biaya lebih tinggi

---

## 4. Media Storage: Cloudflare R2

**Keputusan:** Cloudflare R2

**Alasan:**
- **Zero egress fee** — ini yang paling penting
- S3-compatible API
- Free tier: 10 GB storage, 1M Class A ops, 10M Class B ops per bulan
- Presigned URL support untuk direct upload dari client
- Terintegrasi baik dengan CDN Cloudflare
- Jauh lebih murah dari AWS S3 untuk scale

**Alternatif yang dipertimbangkan:**
- AWS S3 — egress fee mahal
- Supabase Storage — limit lebih kecil
- Backblaze B2 — bagus, tapi ekosistem lebih kecil

---

## 5. Real-time: Ably

**Keputusan:** Ably

**Alasan:**
- Managed WebSocket platform
- Free tier: 6M messages/bulan, 200 concurrent connections
- SDK Flutter tersedia
- Channel-based pub/sub cocok untuk per-circle broadcast
- Presence feature untuk "siapa yang online"
- Reliability dan uptime sangat tinggi

**Alternatif yang dipertimbangkan:**
- Firebase Realtime Database — overkill, coupling tinggi
- Pusher — lebih mahal di scale
- Self-hosted WebSocket — biaya ops tinggi, reliability lebih rendah
- Supabase Realtime — lebih terbatas

---

## 6. Cache / Counter: Upstash Redis

**Keputusan:** Upstash Redis

**Alasan:**
- Serverless Redis, pay-per-request
- Free tier: 10,000 commands/hari
- Latency sangat rendah untuk counter increment
- Tidak perlu manage Redis server
- REST API tersedia selain Redis protocol
- Perfect untuk reaction counter yang butuh atomic increment

**Alternatif yang dipertimbangkan:**
- Redis self-hosted — ops cost tinggi
- Turso untuk counter — terlalu banyak write untuk counter
- In-memory — tidak persistent, tidak shared antar instance

---

## 7. Total Estimasi Biaya MVP

| Service | Free Tier | Estimasi Biaya |
|---|---|---|
| Flutter | Open source | $0 |
| Golang hosting (Railway) | $5 credit | ~$5/bulan |
| Turso | 500 DB, 1B rows read | $0 |
| Cloudflare R2 | 10GB, 10M ops | $0 |
| Ably | 6M messages | $0 |
| Upstash Redis | 10K cmds/day | $0 |
| **Total** | | **~$5/bulan** |

Stack ini dapat menjalankan MVP dengan biaya sangat minimal sambil tetap scalable.
