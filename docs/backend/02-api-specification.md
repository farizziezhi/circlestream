# API Specification

## CircleStream — REST API Reference

---

## 1. Conventions

- Base URL: `https://api.circlestream.app/v1`
- Content-Type: `application/json`
- Auth: `Authorization: Bearer {access_token}`
- All timestamps: ISO 8601 (`2026-01-01T12:00:00Z`)
- Error format:
```json
{
  "error": "error_code",
  "message": "Human-readable message"
}
```

---

## 2. Auth Endpoints

### POST /auth/register
Register user baru.

**Request:**
```json
{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "minimum8chars"
}
```

**Response 201:**
```json
{
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "created_at": "2026-01-01T12:00:00Z"
  },
  "tokens": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "expires_in": 900
  }
}
```

**Errors:**
- `400 email_taken` — email sudah terdaftar
- `400 username_taken` — username sudah dipakai
- `400 validation_error` — input tidak valid

---

### POST /auth/login
Login dan dapat token.

**Request:**
```json
{
  "email": "john@example.com",
  "password": "minimum8chars"
}
```

**Response 200:**
```json
{
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com"
  },
  "tokens": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "expires_in": 900
  }
}
```

**Errors:**
- `401 invalid_credentials` — email/password salah

---

### POST /auth/refresh
Refresh access token.

**Request:**
```json
{
  "refresh_token": "eyJ..."
}
```

**Response 200:**
```json
{
  "access_token": "eyJ...",
  "expires_in": 900
}
```

**Errors:**
- `401 invalid_refresh_token`
- `401 refresh_token_expired`

---

### POST /auth/logout
🔒 Requires Auth

Invalidate refresh token.

**Request:**
```json
{
  "refresh_token": "eyJ..."
}
```

**Response 200:**
```json
{
  "message": "Logged out successfully"
}
```

---

## 3. Circle Endpoints

### POST /circles
🔒 Requires Auth

Buat circle baru.

**Request:**
```json
{
  "name": "Bestie Gang"
}
```

**Response 201:**
```json
{
  "circle": {
    "id": 1,
    "name": "Bestie Gang",
    "owner_id": 1,
    "created_at": "2026-01-01T12:00:00Z"
  },
  "invite_code": {
    "id": 1,
    "code": "XK92PLMW",
    "is_active": true,
    "max_uses": null,
    "expires_at": null
  }
}
```

---

### POST /circles/join
🔒 Requires Auth

Join circle menggunakan invite code.

**Request:**
```json
{
  "invite_code": "XK92PLMW"
}
```

**Response 200:**
```json
{
  "circle": {
    "id": 1,
    "name": "Bestie Gang",
    "member_count": 3
  },
  "member": {
    "user_id": 5,
    "role": "member",
    "joined_at": "2026-01-01T12:00:00Z"
  }
}
```

**Errors:**
- `404 invite_code_not_found`
- `400 invite_code_expired`
- `400 invite_code_exhausted`
- `400 circle_full` — sudah 10 member
- `400 already_member` — user sudah di circle ini

---

### GET /circles/:circle_id
🔒 Requires Auth + Member

Lihat detail circle.

**Response 200:**
```json
{
  "circle": {
    "id": 1,
    "name": "Bestie Gang",
    "owner_id": 1,
    "member_count": 5,
    "created_at": "2026-01-01T12:00:00Z"
  }
}
```

---

### GET /circles/:circle_id/members
🔒 Requires Auth + Member

List semua member circle.

**Response 200:**
```json
{
  "members": [
    {
      "user_id": 1,
      "username": "johndoe",
      "role": "owner",
      "joined_at": "2026-01-01T12:00:00Z"
    },
    {
      "user_id": 5,
      "username": "janedoe",
      "role": "member",
      "joined_at": "2026-01-02T08:00:00Z"
    }
  ]
}
```

---

### POST /circles/:circle_id/leave
🔒 Requires Auth + Member

Leave circle.

**Response 200:**
```json
{
  "message": "Left circle successfully"
}
```

**Errors:**
- `400 owner_cannot_leave` — owner harus transfer atau delete circle dulu

---

### GET /circles/:circle_id/invite-codes
🔒 Requires Auth + Owner

List invite codes milik circle.

**Response 200:**
```json
{
  "invite_codes": [
    {
      "id": 1,
      "code": "XK92PLMW",
      "is_active": true,
      "max_uses": null,
      "used_count": 3,
      "expires_at": null,
      "created_at": "2026-01-01T12:00:00Z"
    }
  ]
}
```

---

### POST /circles/:circle_id/invite-codes
🔒 Requires Auth + Owner

Generate invite code baru.

**Request:**
```json
{
  "max_uses": 1,
  "expires_at": null
}
```

**Response 201:**
```json
{
  "invite_code": {
    "id": 2,
    "code": "AB34WXYZ",
    "is_active": true,
    "max_uses": 1,
    "used_count": 0,
    "expires_at": null
  }
}
```

---

## 4. Media Endpoints

### POST /media/presign-upload
🔒 Requires Auth + Member of circle

Request presigned URL untuk upload ke R2.

**Request:**
```json
{
  "circle_id": 1,
  "filename": "photo.jpg",
  "content_type": "image/jpeg",
  "file_size": 2048000
}
```

**Response 200:**
```json
{
  "upload_url": "https://r2.circlestream.app/...",
  "object_key": "circles/1/posts/temp_abc123.jpg",
  "expires_in": 900
}
```

**Errors:**
- `400 unsupported_file_type` — bukan JPG/JPEG/PNG/WEBP
- `400 file_too_large` — lebih dari 10 MB
- `403 not_member` — bukan member circle

---

### POST /media/finalize
🔒 Requires Auth + Member of circle

Finalize setelah upload berhasil. Simpan metadata dan publish event.

**Request:**
```json
{
  "circle_id": 1,
  "object_key": "circles/1/posts/temp_abc123.jpg",
  "thumbnail_key": "circles/1/posts/thumb_abc123.jpg"
}
```

**Response 201:**
```json
{
  "post": {
    "id": 42,
    "circle_id": 1,
    "user_id": 1,
    "image_url": "https://cdn.circlestream.app/circles/1/posts/temp_abc123.jpg",
    "thumbnail_url": "https://cdn.circlestream.app/circles/1/posts/thumb_abc123.jpg",
    "created_at": "2026-01-01T12:00:00Z"
  }
}
```

---

## 5. Post Endpoints

### GET /circles/:circle_id/posts
🔒 Requires Auth + Member

Load feed circle dengan pagination cursor.

**Query params:**
- `limit` — default 20, max 50
- `cursor` — ISO timestamp untuk pagination (created_at dari post terakhir)

**Response 200:**
```json
{
  "posts": [
    {
      "id": 42,
      "circle_id": 1,
      "user_id": 1,
      "username": "johndoe",
      "image_url": "https://cdn.circlestream.app/...",
      "thumbnail_url": "https://cdn.circlestream.app/...",
      "reaction_counts": {
        "❤️": 5,
        "🔥": 2
      },
      "created_at": "2026-01-01T12:00:00Z"
    }
  ],
  "next_cursor": "2025-12-31T10:00:00Z",
  "has_more": true
}
```

---

### GET /posts/:post_id
🔒 Requires Auth + Member of post's circle

Detail satu post.

**Response 200:**
```json
{
  "post": {
    "id": 42,
    "circle_id": 1,
    "user_id": 1,
    "username": "johndoe",
    "image_url": "https://cdn.circlestream.app/...",
    "thumbnail_url": "https://cdn.circlestream.app/...",
    "reaction_counts": {
      "❤️": 5,
      "🔥": 2
    },
    "created_at": "2026-01-01T12:00:00Z"
  }
}
```

---

## 6. Reaction Endpoints

### POST /posts/:post_id/reactions
🔒 Requires Auth + Member of post's circle

Tambah reaction.

**Request:**
```json
{
  "emoji": "❤️"
}
```

**Response 200:**
```json
{
  "post_id": 42,
  "emoji": "❤️",
  "count": 6
}
```

**Errors:**
- `400 invalid_emoji` — emoji tidak ada di preset

---

### GET /posts/:post_id/reactions
🔒 Requires Auth + Member of post's circle

Get reaction counts untuk satu post.

**Response 200:**
```json
{
  "post_id": 42,
  "reactions": {
    "❤️": 6,
    "😂": 1,
    "🔥": 3
  },
  "total": 10
}
```

---

## 7. HTTP Status Codes

| Status | Penggunaan |
|---|---|
| 200 | Sukses, ada response body |
| 201 | Resource berhasil dibuat |
| 400 | Bad request, validation error |
| 401 | Tidak autentikasi / token invalid |
| 403 | Autentikasi ok, tapi tidak punya akses |
| 404 | Resource tidak ditemukan |
| 500 | Server error |
