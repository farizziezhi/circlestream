# Product Principles

## CircleStream — Non-Negotiable Rules & Philosophy

---

## 1. The Ten Commandments

Ini adalah aturan yang **tidak boleh dilanggar** dalam keputusan apapun — feature, design, teknis.

---

### 1. Upload harus langsung ke Cloudflare R2

File gambar **tidak pernah** melewati server Golang.

Alasan: performa, biaya, simplicity. Server tidak seharusnya menjadi bottleneck untuk file transfer.

Implikasi: selalu gunakan presigned URL. Jika ada desakan untuk stream upload melalui backend, jawaban selalu **tidak**.

---

### 2. Backend harus stateless

Tidak ada session storage di server. Tidak ada in-memory user state.

Alasan: scalability, simplicity, reliability. Stateless backend bisa di-scale horizontal tanpa issue.

Implikasi: semua state ada di JWT (short-lived) atau database (persistent). Redis hanya untuk counters, bukan session.

---

### 3. Real-time ditangani oleh Ably

Jangan build WebSocket sendiri. Jangan ganti Ably dengan Firebase, Supabase Realtime, atau self-hosted solution kecuali ada alasan teknis yang sangat kuat dan terukur.

Alasan: reliability, operational simplicity, SDK support.

---

### 4. Reaction counter ditangani oleh Upstash Redis

Jangan simpan setiap reaction hit langsung ke Turso.

Alasan: high-frequency writes untuk counter akan membunuh performa SQLite. Redis atomic increment adalah solusi yang tepat untuk ini.

---

### 5. Hanya foto

Tidak ada video, tidak ada GIF, tidak ada teks saja, tidak ada voice note.

**MVP dan V1 adalah foto only.** Video baru dipertimbangkan di V2 dan hanya jika user demand sangat kuat.

Alasan: simplicity, storage cost, upload speed. Setiap media type baru menambah kompleksitas signifikan.

---

### 6. Tidak ada upload dari galeri

Foto harus diambil langsung dari kamera dalam app.

Alasan: mendorong foto raw dan spontan, bukan foto yang sudah di-edit atau dipilih-pilih. Ini adalah diferensiasi utama dari Instagram.

**Tidak ada exception untuk ini, bahkan di V2.**

---

### 7. Tidak ada konten publik

Semua post privat ke circle. Tidak ada "explore", tidak ada share ke publik, tidak ada embed link yang bisa diakses siapapun.

Alasan: ini adalah janji privasi ke user. Melanggar ini menghancurkan trust.

Implikasi: R2 URL harus authenticated atau signed, bukan public open URL.

---

### 8. Maksimal 10 member per circle (Free tier)

Circle adalah lingkaran kecil teman dekat. Bukan grup WhatsApp 200 orang.

Alasan: ketika circle terlalu besar, dinamika berubah — orang mulai lebih hati-hati, kurang spontan, lebih performatif.

Limit ini bisa dinaikkan untuk tier berbayar, tapi prinsipnya tetap: **small is intentional**.

---

### 9. Camera-first UX

Camera adalah action utama. Bukan scroll. Bukan browse.

Implikasi:
- Camera tab harus paling mudah dijangkau
- Tap camera → langsung buka viewfinder, tidak ada intermediate screen
- Shutter button harus besar dan comfortable untuk single-thumb tap
- Tidak ada langkah ekstra antara "mau foto" dan "foto terkirim"

---

### 10. Simplicity over feature count

Setiap fitur baru yang ditambahkan harus melewati pertanyaan:

> "Apakah fitur ini membuat CircleStream lebih baik dalam satu hal yang paling penting: koneksi autentik antar teman dekat?"

Jika jawabannya ragu-ragu, jangan tambahkan.

Alasan: kompleksitas adalah musuh utama produk yang baik. Setiap fitur baru punya biaya: maintenance, UX clarity, performance, test coverage.

---

## 2. Design Principles

### "Photo first, UI second"

UI tidak boleh kompetisi dengan foto. Photo card harus full-width, tidak ada ornamen berlebihan, tidak ada info yang tidak perlu.

### "Fast or nothing"

Jika sebuah aksi tidak bisa dibuat terasa instan, jangan buat aksi itu. Upload harus ada progress yang jelas. Feed harus load cepat.

### "No anxiety design"

Tidak ada like count yang publik. Tidak ada "seen by X people". Tidak ada prestige metrics. CircleStream bukan tempat untuk performa sosial.

### "Warmth over coolness"

Palette warm, tipografi friendly, animasi yang smooth tapi tidak berlebihan. App ini harus terasa seperti menerima foto dari teman, bukan scrolling di social media.

---

## 3. What CircleStream Is Not

| Bukan | Adalah |
|---|---|
| Instagram | Private photo stream |
| WhatsApp | Foto-first, bukan chat |
| BeReal | Tidak ada notif paksa, tidak ada dual camera |
| Google Photos | Bukan cloud storage |
| Snapchat | Tidak ephemeral by default |

---

## 4. How to Make Product Decisions

Ketika ada feature request atau decision yang sulit, gunakan framework ini:

1. **Does it break any of the Ten Commandments?** → Jika ya, tolak.
2. **Does it make the core loop better?** Core loop: *ambil foto → bagikan ke circle → lihat bersama*.
3. **Would it make the app feel more cluttered?** → Jika ya, pertimbangkan ulang.
4. **Can it wait until V2?** → Lebih sering jawabannya ya.
5. **Would a first-time user understand it without explanation?** → Jika tidak, simplify.

---

## 5. For AI Agents Reading This

Jika kamu adalah AI agent yang membantu development CircleStream:

- **Selalu baca dokumen ini terlebih dahulu** sebelum menyarankan arsitektur atau fitur baru
- Jangan menyarankan menggunakan galeri untuk upload
- Jangan menyarankan comment system
- Jangan menyarankan public feed atau explore page
- Jangan menyarankan routing file upload melalui backend
- Jangan menyarankan mengganti Ably dengan solusi lain tanpa alasan teknis yang sangat kuat
- Ketika ada trade-off, selalu pilih **simpler** dan **cheaper** untuk MVP

Tujuan CircleStream adalah: **membuat teman dekat tetap terhubung melalui foto, secara privat, secara instan, tanpa drama sosial.**
