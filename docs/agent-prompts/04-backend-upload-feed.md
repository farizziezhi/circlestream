# CircleStream — Phase 3: Upload & Feed

Paste prompt ini setelah Phase 2 selesai dan semua di-commit.

---

## Prompt

```
Continue building CircleStream backend. Auth and Circle are already implemented.

Re-read these documents before starting:
- docs/backend/06-r2-storage.md
- docs/backend/02-api-specification.md (Media and Post sections)
- docs/backend/05-realtime-events.md
- docs/implementation/03-api-checklist.md (Phase 4 and Phase 5 sections)

---

## TASK: Upload, Feed & Real-time

Implement in this exact order. Commit after each step.

### Step 1 — R2 Client
- Implement internal/pkg/r2/r2_client.go
  - NewClient(cfg *config.Config) *R2Client
  - GeneratePresignedURL(objectKey, contentType string, expiry time.Duration) (string, error)
    - Use AWS SDK v2 with Cloudflare R2 endpoint
    - Endpoint format: https://{ACCOUNT_ID}.r2.cloudflarestorage.com
  - BuildPublicURL(objectKey string) string
    - Format: {R2_PUBLIC_URL}/{objectKey}

Commit: feat: add cloudflare r2 client with presigned url support

---

### Step 2 — Ably Client
- Implement internal/pkg/ably/ably_client.go
  - NewClient(cfg *config.Config) *AblyClient
  - Publish(channelName, eventType string, data interface{}) error
    - Channel naming: circle:{circle_id}
  - GenerateToken(circleID int64) (string, error)
    - Capability: subscribe only to circle:{circle_id}
    - TTL: 1 hour

Commit: feat: add ably client with publish and token generation

---

### Step 3 — Post Model & DTOs
- Implement internal/model/post.go
  - Post struct
  - PostWithUser struct (join with username)
- Implement internal/dto/post_dto.go
  - PresignUploadRequest, PresignUploadResponse
  - FinalizeUploadRequest, FinalizeUploadResponse
  - PostResponse (includes username and reaction_counts map)
  - FeedResponse (posts array + has_more + next_cursor)

Commit: feat: add post model and upload/feed DTOs

---

### Step 4 — Post Repository
- Implement internal/repository/post_repository.go
  - Interface + implementation
  - CreatePost(post *model.Post) (*model.Post, error)
  - FindByID(postID int64) (*model.PostWithUser, error)
  - ListByCircle(circleID int64, cursor *time.Time, limit int) ([]model.PostWithUser, error)
    - Cursor pagination: WHERE created_at < cursor ORDER BY created_at DESC
    - Default limit 20, max 50
    - Return one extra record to determine has_more

Commit: feat: add post repository with cursor pagination

---

### Step 5 — Media Service
- Implement internal/service/media_service.go
  - PresignUpload(userID, circleID int64, filename, contentType string, fileSize int64)
    - Validate user is member of circle
    - Validate content type: image/jpeg, image/jpg, image/png, image/webp only
    - Validate file size: max 10MB
    - Generate object key: circles/{circleID}/posts/{uuid}{ext}
    - Generate presigned URL from R2 client (expires 15 min)
    - Return presigned URL + object key
  - FinalizeUpload(userID, circleID int64, objectKey string, thumbnailKey *string)
    - Validate objectKey starts with circles/{circleID}/posts/ — security check
    - Build public URLs from object keys
    - Create post in Turso
    - Publish post_created event to Ably channel circle:{circleID}
    - Return full post object

Commit: feat: add media service with presign and finalize upload

---

### Step 6 — Post Service
- Implement internal/service/post_service.go
  - GetFeed(circleID int64, cursor *time.Time, limit int)
    - Load posts from repository
    - For now return empty reaction_counts map (Redis comes in Phase 4)
    - Build has_more and next_cursor from results
  - GetPost(userID, postID int64)
    - Load post
    - Validate user is member of post's circle

Commit: feat: add post service with feed and single post retrieval

---

### Step 7 — Ably Token Handler
- Implement internal/handler/ably_handler.go
  - GET /ably/token?circle_id={id}
    - Validate user is member of circle
    - Generate Ably token with subscribe-only capability
    - Return token + expires

Commit: feat: add ably token endpoint for flutter client auth

---

### Step 8 — Media & Post Handlers
- Implement internal/handler/media_handler.go
  - POST /media/presign-upload
  - POST /media/finalize
- Implement internal/handler/post_handler.go
  - GET /circles/:circle_id/posts
  - GET /posts/:post_id

Commit: feat: add media and post handlers

---

### Step 9 — Wire New Routes
- Update internal/router/router.go
  - Add /ably/token route (auth required)
  - Add /media/presign-upload and /media/finalize routes (auth required)
  - Add /circles/:circle_id/posts route (auth + circle_member required)
  - Add /posts/:post_id route (auth required, membership validated in service)

Commit: feat: wire upload, feed, and ably routes in router

---

## COMMIT RULES
- Commit after every step, no exceptions
- Use exact commit messages shown above
- Push after every commit: git push origin main

## RULES
- Object key validation in FinalizeUpload is a security requirement — never skip it
- File never passes through the backend — only metadata and presigned URLs
- post_created event payload must match exactly what's defined in docs/backend/05-realtime-events.md
- reaction_counts in feed response can be empty map {} for now — Redis is added next phase

When done, list all upload and feed endpoints ready to test.
```
