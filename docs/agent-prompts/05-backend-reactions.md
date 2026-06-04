# CircleStream — Phase 4: Reactions & Real-time

Paste prompt ini setelah Phase 3 selesai dan semua di-commit.

---

## Prompt

```
Continue building CircleStream backend. Auth, Circle, Upload, and Feed are already implemented.

Re-read these documents before starting:
- docs/backend/07-upstash-reactions.md
- docs/backend/05-realtime-events.md
- docs/backend/02-api-specification.md (Reaction section)
- docs/implementation/03-api-checklist.md (Phase 6 section)

---

## TASK: Reactions + Redis Counter + Remaining Real-time Events

Implement in this exact order. Commit after each step.

### Step 1 — Redis Client
- Implement internal/pkg/redis/redis_client.go
  - NewClient(cfg *config.Config) *RedisClient
  - Use TLS connection (Upstash requires TLS)
  - IncrReaction(ctx, postID int64, emoji string) (int64, error)
    - Key pattern: reaction:count:{postID}:{emoji}
    - Use INCR command
  - GetReactionCounts(ctx, postID int64) (map[string]int64, error)
    - Pipeline GET for all 8 preset emojis at once
    - Return only emojis with count > 0
  - GetReactionCountsBatch(ctx, postIDs []int64) (map[int64]map[string]int64, error)
    - Pipeline all emojis for all postIDs in one round trip
    - Used for enriching feed response
  - DeletePostReactions(ctx, postID int64) error
    - DEL all reaction keys for a post (for future delete post feature)

Commit: feat: add upstash redis client with reaction counter operations

---

### Step 2 — Reaction Model & DTOs
- Implement internal/model/reaction.go
  - Reaction struct
- Implement internal/dto/reaction_dto.go
  - AddReactionRequest { Emoji string }
  - AddReactionResponse { PostID, Emoji, Count }
  - GetReactionsResponse { PostID, Reactions map[string]int64, Total int64 }

Commit: feat: add reaction model and DTOs

---

### Step 3 — Reaction Repository
- Implement internal/repository/reaction_repository.go
  - Interface + implementation
  - CreateReaction(reaction *model.Reaction) error
    - Insert to Turso as persistent backup
    - This runs async (goroutine) — do not block the response on this

Commit: feat: add reaction repository for turso backup

---

### Step 4 — Reaction Service
- Implement internal/service/reaction_service.go
  - AddReaction(userID, postID int64, emoji string)
    1. Validate emoji is in preset whitelist
    2. Validate user is member of post's circle
    3. Increment counter in Redis (atomic INCR)
    4. Save to Turso async (goroutine, non-blocking)
    5. Publish reaction_added event to Ably
    6. Return post_id, emoji, new count
  - GetReactions(userID, postID int64)
    1. Validate user is member of post's circle
    2. Read all counts from Redis pipeline
    3. Return counts map + total

  Emoji whitelist: ❤️ 😂 😮 🔥 👏 😢 🤩 💀

Commit: feat: add reaction service with redis counter and ably publish

---

### Step 5 — Update Post Service Feed
- Update internal/service/post_service.go GetFeed()
  - After loading posts, enrich with reaction counts from Redis
  - Use GetReactionCountsBatch() to fetch all post counts in one pipeline call
  - Assign reaction_counts to each PostResponse

Commit: feat: enrich feed response with reaction counts from redis

---

### Step 6 — Reaction Handler
- Implement internal/handler/reaction_handler.go
  - POST /posts/:post_id/reactions → AddReaction
  - GET /posts/:post_id/reactions → GetReactions

Commit: feat: add reaction handler

---

### Step 7 — Wire Reaction Routes + Remaining Events
- Update internal/router/router.go
  - Add reaction routes (auth required, membership validated in service)
- Update internal/service/circle_service.go
  - JoinCircle() → publish member_joined event after successful join
  - LeaveCircle() → publish member_left event after successful leave
- Update internal/handler/circle_handler.go if needed for circle_updated event

Commit: feat: wire reaction routes and add remaining realtime events

---

### Step 8 — Final Cleanup
- Make sure all event payloads match exactly what's in docs/backend/05-realtime-events.md
- Make sure all API response formats match docs/backend/02-api-specification.md
- Make sure /health endpoint also checks Redis and DB connectivity
- Run: go build ./... (must compile with zero errors)
- Run: go vet ./... (must pass with zero warnings)

Commit: chore: final cleanup, all endpoints implemented and compiling

---

## COMMIT RULES
- Commit after every step, no exceptions
- Use exact commit messages shown above
- Push after every commit: git push origin main

## RULES
- Redis INCR is atomic — no race conditions, no mutex needed
- Turso reaction insert must be async (goroutine) — never block the API response waiting for it
- Emoji validation is server-side required even if Flutter also validates
- All Ably event payloads must match docs/backend/05-realtime-events.md exactly

When done, confirm all endpoints are implemented and list the full API surface.
```
