# System Architecture

## CircleStream — Architecture Overview

---

## 1. High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter App                         │
│              (Android / iOS Client)                     │
└────────┬──────────────┬──────────────┬──────────────────┘
         │              │              │
         │ REST API      │ Direct Upload│ WebSocket
         ▼              ▼              ▼
┌──────────────┐ ┌─────────────┐ ┌──────────────┐
│ Golang Fiber │ │Cloudflare R2│ │    Ably      │
│  Backend API │ │   Storage   │ │  Real-time   │
└──────┬───────┘ └─────────────┘ └──────────────┘
       │
       ├──────────────────┐
       ▼                  ▼
┌─────────────┐    ┌─────────────┐
│    Turso    │    │   Upstash   │
│  Database   │    │    Redis    │
│  (SQLite)   │    │  (Counters) │
└─────────────┘    └─────────────┘
```

---

## 2. Upload Flow

```
Flutter                  Backend (Golang)         Cloudflare R2
   │                           │                       │
   │── compress / resize ──▶   │                       │
   │                           │                       │
   │── POST /media/presign ──▶ │                       │
   │                           │── generate presigned  │
   │                           │   URL ──────────────▶ │
   │                           │◀── presigned URL ─────│
   │◀── presigned URL ─────────│                       │
   │                           │                       │
   │── PUT image directly ─────────────────────────▶   │
   │◀── 200 OK ────────────────────────────────────────│
   │                           │                       │
   │── POST /media/finalize ──▶│                       │
   │                           │── save metadata ──▶ Turso
   │                           │── publish event ──▶ Ably
   │◀── post object ───────────│                       │
```

**Prinsip penting:**
- File gambar **tidak pernah melewati** server Golang
- Golang hanya menangani metadata dan presigned URL generation
- R2 menerima upload langsung dari Flutter

---

## 3. Reaction Flow

```
Flutter                  Backend (Golang)      Upstash Redis    Ably
   │                           │                    │             │
   │── POST /reactions ───────▶│                    │             │
   │                           │── INCR counter ──▶ │             │
   │                           │◀── new count ──────│             │
   │                           │── publish event ───────────────▶│
   │                           │◀── 200 OK          │             │
   │◀── reaction response ─────│                    │             │
   │                                                              │
   │◀──────────── reaction_added event ───────────────────────────│
   │  (semua member circle menerima event ini)
```

---

## 4. Real-time Feed Flow

```
Poster Device            Backend              Ably         Viewer Devices
     │                      │                  │                │
     │── POST /posts ──────▶│                  │                │
     │                      │── save to Turso  │                │
     │                      │── publish ──────▶│                │
     │                      │                  │── push event ─▶│
     │◀── 200 OK ───────────│                  │                │
                                               │                │
                                               │  (semua member │
                                               │  lain menerima │
                                               │  post_created) │
```

---

## 5. Authentication Flow

```
Client                    Backend                  Turso
  │                          │                       │
  │── POST /auth/login ─────▶│                       │
  │                          │── query user ────────▶│
  │                          │◀── user row ──────────│
  │                          │── verify bcrypt       │
  │                          │── generate JWT        │
  │◀── access + refresh token│                       │
  │                          │                       │
  │── request + Bearer ─────▶│                       │
  │                          │── validate JWT        │
  │◀── protected response ───│                       │
```

---

## 6. Service Responsibilities

| Service | Tanggung Jawab |
|---|---|
| **Golang Fiber** | Auth, business logic, presigned URL, metadata, event publish |
| **Turso** | Persistent data: users, circles, posts, reactions metadata |
| **Cloudflare R2** | Binary storage untuk semua file gambar |
| **Ably** | Real-time message broadcast ke semua client |
| **Upstash Redis** | Reaction counters, fast-read cache |
| **Flutter** | UI, kamera, image compression, Ably subscription |

---

## 7. Circle Channel Naming (Ably)

Setiap circle memiliki Ably channel sendiri:

```
channel name: circle:{circle_id}
```

Semua event dalam satu circle di-publish ke channel yang sama.

---

## 8. Security Boundaries

- JWT divalidasi di setiap request ke Backend
- Backend memverifikasi user adalah member circle sebelum memproses request circle-scoped
- Presigned URL R2 hanya bisa digunakan sekali dan expires 15 menit
- Redis counter tidak bisa diakses langsung dari client
- Ably channel hanya bisa di-subscribe oleh token yang digenerate backend

---

## 9. Deployment Topology

```
Flutter App ─── deployed via App Store / Play Store
Golang API  ─── Railway / Fly.io / VPS (single container)
Turso       ─── Turso Cloud (edge SQLite)
R2          ─── Cloudflare R2 (S3-compatible)
Ably        ─── Ably Cloud
Redis       ─── Upstash Redis Cloud
```
