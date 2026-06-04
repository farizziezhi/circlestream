# Agent Prompts — Overview

## CircleStream — Panduan Penggunaan Prompt untuk AI Agent

---

## Urutan Penggunaan

Jalankan prompt secara berurutan. Jangan lompat ke prompt berikutnya sebelum yang sebelumnya selesai dan semua perubahan ter-commit ke GitHub.

---

## Daftar Prompt

| File | Tahap | Isi |
|---|---|---|
| `01-init-backend.md` | Setup awal | Monorepo structure, Go project init, .gitignore, .env.example |
| `02-backend-auth.md` | Phase 1 | Database, migrations, password, JWT, auth endpoints |
| `03-backend-circle.md` | Phase 2 | Circle CRUD, invite code, member management |
| `04-backend-upload-feed.md` | Phase 3 | R2 presign, finalize upload, feed endpoints, Ably client |
| `05-backend-reactions.md` | Phase 4 | Redis counter, reaction endpoints, semua realtime events |

---

## Cara Pakai

1. Buka file prompt yang sesuai tahap
2. Copy seluruh isi blok kode (dari ``` sampai ```)
3. Paste ke Antigravity
4. Tunggu sampai agent selesai dan konfirmasi semua step done
5. Verifikasi commit muncul di https://github.com/farizziezhi/circlestream
6. Lanjut ke prompt berikutnya

---

## Checklist Sebelum Lanjut ke Prompt Berikutnya

Sebelum pindah ke prompt berikutnya, pastikan:

- [ ] Semua step dalam prompt sudah selesai
- [ ] Semua commit sudah muncul di GitHub
- [ ] `go build ./...` berjalan tanpa error
- [ ] Tidak ada `.env` yang ter-commit

---

## Struktur Folder Hasil Akhir

Setelah semua 5 prompt selesai, repo akan punya struktur:

```
circlestream/                         ← root monorepo
├── README.md
├── .gitignore
├── docs/                             ← semua dokumentasi
│   ├── agent-prompts/               ← prompt-prompt ini
│   └── ...
└── backend/                         ← Golang API
    ├── cmd/api/main.go
    ├── internal/
    │   ├── config/
    │   ├── database/
    │   ├── handler/
    │   ├── middleware/
    │   ├── model/
    │   ├── dto/
    │   ├── pkg/
    │   ├── repository/
    │   ├── router/
    │   └── service/
    ├── .env.example
    ├── go.mod
    ├── go.sum
    ├── Dockerfile
    └── Makefile
```

Flutter app (`app/`) akan ditambahkan di prompt selanjutnya setelah backend selesai.

---

## Notes

- Semua prompt menggunakan conventional commit format
- Agent melakukan `git push` setelah setiap commit — pastikan GitHub credentials sudah di-setup di environment agent
- Jika agent stuck atau skip langkah, ingatkan dengan: *"You missed step X, please complete it and commit before continuing"*
