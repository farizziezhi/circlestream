# Domain Model

## CircleStream — Entities, Relationships, and Business Rules

---

## 1. Core Entities

### User
Represents a registered account.

```
User {
  id          : UUID / integer PK
  username    : string, unique
  email       : string, unique
  password_hash: string (bcrypt/argon2id)
  created_at  : timestamp
}
```

**Rules:**
- Username harus unik
- Email harus unik
- Password disimpan sebagai hash, tidak pernah plain text
- User bisa menjadi member di banyak circle
- User bisa menjadi owner di banyak circle

---

### Circle
Represents a private group.

```
Circle {
  id          : integer PK
  name        : string
  owner_id    : FK → User
  created_at  : timestamp
}
```

**Rules:**
- Harus punya satu owner
- Maksimal 10 member (termasuk owner)
- Owner adalah member pertama secara otomatis
- Konten circle hanya terlihat oleh member

---

### CircleMember
Join table antara User dan Circle.

```
CircleMember {
  circle_id   : FK → Circle
  user_id     : FK → User
  role        : enum('owner', 'member')
  joined_at   : timestamp
}
```

**Rules:**
- Kombinasi (circle_id, user_id) harus unik
- Role 'owner' hanya satu per circle
- Owner tidak bisa leave tanpa transfer/delete

---

### InviteCode
Manages circle invitations.

```
InviteCode {
  id          : integer PK
  circle_id   : FK → Circle
  code        : string, unique
  is_active   : boolean
  expires_at  : timestamp (nullable)
  max_uses    : integer (nullable, null = unlimited)
  used_count  : integer, default 0
  created_at  : timestamp
}
```

**Rules:**
- Code harus unik secara global
- Code bisa sekali pakai (max_uses = 1) atau multi-use
- Code bisa punya expiry atau tidak
- is_active = false menonaktifkan code tanpa menghapus

---

### Post
Represents a photo shared in a circle.

```
Post {
  id            : integer PK
  circle_id     : FK → Circle
  user_id       : FK → User
  image_url     : string (R2 URL)
  thumbnail_url : string (R2 URL, nullable)
  created_at    : timestamp
}
```

**Rules:**
- Hanya satu foto per post
- Tidak ada caption panjang
- Foto harus di-upload langsung ke R2
- URL disimpan setelah upload berhasil
- Hanya member circle yang bisa melihat post

---

### Reaction
Represents an emoji reaction to a post.

```
Reaction {
  id          : integer PK
  post_id     : FK → Post
  user_id     : FK → User
  emoji       : string (dari preset)
  created_at  : timestamp
}
```

**Rules:**
- Emoji harus dari preset yang diizinkan
- User bisa bereaksi dengan emoji yang sama lebih dari satu kali (ditentukan product)
- Reaction count di-cache di Redis untuk performa

**Emoji Presets:**
```
❤️  😂  😮  🔥  👏  😢  🤩  💀
```

---

## 2. Entity Relationship Diagram

```
User ─────────────────────────── owns ─── Circle
  │                                           │
  │ many                               has many│
  │                                           │
  └── CircleMember ──────────────────────────┘
         (pivot)

Circle ──── has many ──── InviteCode

Circle ──── has many ──── Post ──── has many ──── Reaction
                            │
                          posted by
                            │
                           User
```

---

## 3. Business Rules Summary

### Circle Rules
1. Circle bersifat privat — tidak ada konten publik
2. Maksimal 10 member per circle
3. Hanya member yang bisa melihat post dan member list
4. Owner adalah satu-satunya role khusus

### Invite Rules
1. Invite code harus digunakan untuk join
2. Code bisa single-use atau multi-use
3. Code expired atau is_active=false tidak bisa digunakan
4. Join gagal jika circle sudah penuh (10 member)
5. User tidak bisa join circle yang sudah di-join

### Post Rules
1. Hanya foto (JPG, JPEG, PNG, WEBP)
2. Max 10 MB sebelum kompresi, target ≤ 3 MB
3. Foto diambil dari kamera, bukan galeri
4. Foto harus upload ke R2 sebelum post di-create

### Reaction Rules
1. Emoji harus dari preset
2. Counter di-increment di Redis (atomic)
3. Persistensi backup di tabel reactions Turso

---

## 4. Value Objects

### ImageURL
- Format: `https://r2.circlestream.app/{circle_id}/{post_id}/{filename}`
- Harus HTTPS
- Domain dari R2 bucket

### InviteCode Format
- 8 karakter alphanumeric uppercase
- Contoh: `XK92PLMW`
- Generated secara random, dijamin unik

### JWT Claims
```json
{
  "sub": "user_id",
  "username": "johndoe",
  "exp": 1234567890,
  "iat": 1234567890,
  "type": "access" | "refresh"
}
```
