# API Implementation Checklist

## CircleStream — Backend Development Tracker

Gunakan dokumen ini sebagai checklist saat mengimplementasikan backend.
Tandai setiap item saat selesai.

---

## Phase 1: Foundation

### Project Setup
- [ ] `go mod init circlestream`
- [ ] Install semua dependencies (`go mod tidy`)
- [ ] Setup `.env` dari `.env.example`
- [ ] Setup Makefile
- [ ] Setup Dockerfile
- [ ] Buat folder structure lengkap

### Database
- [ ] Setup Turso client (`internal/database/turso.go`)
- [ ] Buat migration runner (`internal/database/migrations/migrate.go`)
- [ ] Tulis `001_initial.sql`
- [ ] Tulis `002_add_refresh_tokens.sql`
- [ ] Verifikasi semua tabel terbuat

### Config
- [ ] Implement `internal/config/config.go`
- [ ] Semua env vars ter-load
- [ ] Panic jika required env var tidak ada

---

## Phase 2: Auth

### Models & DTOs
- [ ] `internal/model/user.go`
- [ ] `internal/dto/auth_dto.go` (RegisterRequest, LoginRequest, TokenResponse)

### Repository
- [ ] `internal/repository/user_repository.go`
  - [ ] `CreateUser()`
  - [ ] `FindByEmail()`
  - [ ] `FindByUsername()`
  - [ ] `FindByID()`
- [ ] `internal/repository/token_repository.go`
  - [ ] `SaveRefreshToken()`
  - [ ] `FindRefreshToken()`
  - [ ] `DeleteRefreshToken()`

### Packages
- [ ] `internal/pkg/password/password.go`
  - [ ] `Hash()`
  - [ ] `Compare()`
- [ ] `internal/pkg/jwt/jwt.go`
  - [ ] `GenerateAccessToken()`
  - [ ] `GenerateRefreshToken()`
  - [ ] `ValidateToken()`

### Service
- [ ] `internal/service/auth_service.go`
  - [ ] `Register()`
  - [ ] `Login()`
  - [ ] `Refresh()`
  - [ ] `Logout()`

### Handler
- [ ] `internal/handler/auth_handler.go`
  - [ ] `POST /auth/register`
  - [ ] `POST /auth/login`
  - [ ] `POST /auth/refresh`
  - [ ] `POST /auth/logout`

### Middleware
- [ ] `internal/middleware/auth.go` — JWT validation
- [ ] `internal/middleware/rate_limit.go` — Auth rate limiter

### Tests
- [ ] Register success
- [ ] Register duplicate email
- [ ] Register duplicate username
- [ ] Login success
- [ ] Login wrong password
- [ ] Refresh valid token
- [ ] Refresh expired token
- [ ] Logout

---

## Phase 3: Circle

### Models & DTOs
- [ ] `internal/model/circle.go`
- [ ] `internal/model/invite_code.go`
- [ ] `internal/dto/circle_dto.go`

### Repository
- [ ] `internal/repository/circle_repository.go`
  - [ ] `CreateCircle()`
  - [ ] `FindByID()`
  - [ ] `GetMemberCount()`
  - [ ] `AddMember()`
  - [ ] `RemoveMember()`
  - [ ] `GetMembers()`
  - [ ] `IsMember()`
  - [ ] `GetMemberRole()`
- [ ] `internal/repository/invite_repository.go`
  - [ ] `CreateInviteCode()`
  - [ ] `FindByCode()`
  - [ ] `IncrementUsedCount()`
  - [ ] `DeactivateCode()`
  - [ ] `ListByCircle()`

### Middleware
- [ ] `internal/middleware/circle_member.go`
- [ ] `internal/middleware/circle_owner.go`

### Service
- [ ] `internal/service/circle_service.go`
  - [ ] `CreateCircle()` — buat circle + invite code pertama + add owner sebagai member
  - [ ] `JoinCircle()` — validasi code + add member + increment used_count
  - [ ] `LeaveCircle()` — validasi bukan owner + remove member
  - [ ] `GetDetail()`
  - [ ] `GetMembers()`
  - [ ] `CreateInviteCode()`
  - [ ] `ListInviteCodes()`

### Handler
- [ ] `internal/handler/circle_handler.go`
  - [ ] `POST /circles`
  - [ ] `POST /circles/join`
  - [ ] `GET /circles/:circle_id`
  - [ ] `GET /circles/:circle_id/members`
  - [ ] `POST /circles/:circle_id/leave`
  - [ ] `GET /circles/:circle_id/invite-codes`
  - [ ] `POST /circles/:circle_id/invite-codes`

### Tests
- [ ] Create circle
- [ ] Join circle valid code
- [ ] Join circle invalid code
- [ ] Join circle full (10 members)
- [ ] Join circle already member
- [ ] Leave circle (member)
- [ ] Leave circle (owner → error)
- [ ] Non-member cannot access circle endpoints

---

## Phase 4: Media & Upload

### Packages
- [ ] `internal/pkg/r2/r2_client.go`
  - [ ] `GeneratePresignedURL()`
  - [ ] `BuildPublicURL()`

### Service
- [ ] `internal/service/media_service.go`
  - [ ] `PresignUpload()` — validasi + generate presigned URL
  - [ ] `FinalizeUpload()` — validasi object key + simpan post + publish event

### Handler
- [ ] `internal/handler/media_handler.go`
  - [ ] `POST /media/presign-upload`
  - [ ] `POST /media/finalize`

### Tests
- [ ] Presign valid request
- [ ] Presign invalid file type
- [ ] Presign file too large
- [ ] Presign non-member → 403
- [ ] Finalize valid
- [ ] Finalize object key mismatch → 403

---

## Phase 5: Feed & Posts

### Models & DTOs
- [ ] `internal/model/post.go`
- [ ] `internal/dto/post_dto.go`

### Repository
- [ ] `internal/repository/post_repository.go`
  - [ ] `CreatePost()`
  - [ ] `FindByID()`
  - [ ] `ListByCircle()` — dengan cursor pagination

### Service
- [ ] `internal/service/post_service.go`
  - [ ] `GetFeed()` — load posts + enrich dengan reaction counts dari Redis
  - [ ] `GetPost()`

### Handler
- [ ] `internal/handler/post_handler.go`
  - [ ] `GET /circles/:circle_id/posts`
  - [ ] `GET /posts/:post_id`

### Tests
- [ ] Load feed dengan pagination
- [ ] Load feed empty
- [ ] Load feed non-member → 403
- [ ] Get single post

---

## Phase 6: Reactions

### Packages
- [ ] `internal/pkg/redis/redis_client.go`
  - [ ] `IncrReaction()`
  - [ ] `GetReactionCounts()`
  - [ ] `GetAllReactionCounts()` — pipeline untuk multiple posts

### Repository
- [ ] `internal/repository/reaction_repository.go`
  - [ ] `CreateReaction()` — insert ke Turso (backup)

### Service
- [ ] `internal/service/reaction_service.go`
  - [ ] `AddReaction()` — increment Redis + save Turso + publish Ably
  - [ ] `GetReactions()` — baca dari Redis

### Handler
- [ ] `internal/handler/reaction_handler.go`
  - [ ] `POST /posts/:post_id/reactions`
  - [ ] `GET /posts/:post_id/reactions`

### Tests
- [ ] Add valid reaction
- [ ] Add invalid emoji → 400
- [ ] Add reaction non-member → 403
- [ ] Get reaction counts
- [ ] Counter increments correctly

---

## Phase 7: Real-time

### Packages
- [ ] `internal/pkg/ably/ably_client.go`
  - [ ] `Publish()` — publish event ke channel
  - [ ] `GenerateToken()` — generate Ably token untuk client

### Handler
- [ ] `internal/handler/ably_handler.go`
  - [ ] `GET /ably/token` — generate token untuk member circle

### Integration
- [ ] `post_created` dikirim saat finalize upload
- [ ] `reaction_added` dikirim saat add reaction
- [ ] `member_joined` dikirim saat join circle
- [ ] `member_left` dikirim saat leave circle

---

## Phase 8: Final

### Router
- [ ] Semua route terdaftar di `internal/router/router.go`
- [ ] Semua middleware terpasang
- [ ] Health check endpoint

### Error Handling
- [ ] Semua handler return error yang konsisten
- [ ] 400/401/403/404/500 dipakai dengan tepat

### Security Audit
- [ ] JWT divalidasi di semua protected endpoints
- [ ] Circle membership dicek di semua circle-scoped endpoints
- [ ] Object key R2 divalidasi saat finalize
- [ ] Emoji divalidasi dari whitelist
- [ ] File size dan type divalidasi

### Environment
- [ ] `.gitignore` mencakup `.env`
- [ ] `.env.example` lengkap

---

## Validation Rules Reference

| Field | Rule |
|---|---|
| email | format valid, unik |
| username | min 3 char, max 30 char, alphanumeric+underscore |
| password | min 8 char |
| circle name | min 1 char, max 50 char |
| file type | jpg, jpeg, png, webp |
| file size | max 10MB |
| emoji | dari preset whitelist |
| invite code | 8 char alphanumeric uppercase |
| circle members | max 10 |
