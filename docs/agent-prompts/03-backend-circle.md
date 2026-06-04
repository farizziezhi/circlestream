# CircleStream — Phase 2: Circle

Paste prompt ini setelah Phase 1 selesai dan semua di-commit.

---

## Prompt

```
Continue building CircleStream backend. Auth is already implemented and working.

Re-read these documents before starting:
- docs/backend/02-api-specification.md (Circle and Invite Code sections)
- docs/backend/09-security-model.md
- docs/04-domain-model.md (Circle, CircleMember, InviteCode entities)
- docs/implementation/03-api-checklist.md (Phase 3: Circle section)

---

## TASK: Circle Implementation

Implement in this exact order. Commit after each step.

### Step 1 — Models & DTOs
- Implement internal/model/circle.go
  - Circle struct
  - CircleMember struct
- Implement internal/model/invite_code.go
  - InviteCode struct
- Implement internal/dto/circle_dto.go
  - CreateCircleRequest, CreateCircleResponse
  - JoinCircleRequest, JoinCircleResponse
  - CircleDetailResponse, MembersResponse
  - CreateInviteCodeRequest, InviteCodeResponse

Commit: feat: add circle, member, invite code models and DTOs

---

### Step 2 — Circle & Invite Repositories
- Implement internal/repository/circle_repository.go
  - Interface + implementation
  - CreateCircle()
  - FindByID()
  - GetMemberCount()
  - AddMember()
  - RemoveMember()
  - GetMembers()
  - IsMember()
  - GetMemberRole()
- Implement internal/repository/invite_repository.go
  - Interface + implementation
  - CreateInviteCode()
  - FindByCode()
  - IncrementUsedCount()
  - DeactivateCode()
  - ListByCircle()

Commit: feat: add circle and invite code repositories

---

### Step 3 — Circle Middleware
- Implement internal/middleware/circle_member.go
  - Extract circle_id from URL params
  - Check user is member of that circle
  - Set circle_id to fiber.Ctx locals
  - Return 403 if not member
- Implement internal/middleware/circle_owner.go
  - Check user has role 'owner' in circle
  - Return 403 if not owner

Commit: feat: add circle member and owner middleware

---

### Step 4 — Invite Code Generator
Add to internal/pkg or as a helper in circle service:
- generateInviteCode() string
  - 8 characters, uppercase alphanumeric
  - Must be unique — check DB, regenerate if collision

Commit: feat: add invite code generator utility

---

### Step 5 — Circle Service
- Implement internal/service/circle_service.go
  - CreateCircle(userID int64, name string)
    - Create circle
    - Add creator as member with role 'owner'
    - Generate initial invite code (unlimited uses, no expiry)
    - Return circle + invite code
  - JoinCircle(userID int64, code string)
    - Validate code (active, not expired, not exhausted)
    - Check circle not full (max 10 members)
    - Check user not already a member
    - Add user as member
    - Increment used_count
    - Return circle + member info
  - LeaveCircle(userID int64, circleID int64)
    - Reject if user is owner (return error owner_cannot_leave)
    - Remove user from circle_members
  - GetDetail(circleID int64) 
  - GetMembers(circleID int64)
  - CreateInviteCode(circleID int64, maxUses *int, expiresAt *time.Time)
  - ListInviteCodes(circleID int64)

Commit: feat: add circle service with full circle management logic

---

### Step 6 — Circle Handler
- Implement internal/handler/circle_handler.go
  - POST /circles → Create
  - POST /circles/join → Join
  - GET /circles/:circle_id → Detail
  - GET /circles/:circle_id/members → Members
  - POST /circles/:circle_id/leave → Leave
  - GET /circles/:circle_id/invite-codes → ListInviteCodes (owner only)
  - POST /circles/:circle_id/invite-codes → CreateInviteCode (owner only)
  - Follow exact request/response format from docs/backend/02-api-specification.md

Commit: feat: add circle handler with all circle endpoints

---

### Step 7 — Wire Circle Routes
- Update internal/router/router.go
  - Add all circle routes
  - Apply auth middleware to all circle routes
  - Apply circle_member middleware to circle-scoped routes
  - Apply circle_owner middleware to owner-only routes

Commit: feat: wire circle routes in router

---

## COMMIT RULES
- Commit after every step, no exceptions
- Use exact commit messages shown above
- Push after every commit: git push origin main

## RULES
- Use transactions for operations that touch multiple tables (e.g. CreateCircle touches circles + circle_members + invite_codes)
- Validate max 10 members in service layer, not just handler
- Invite code must be validated for: active, not expired, not exhausted, circle not full, user not already member
- Owner cannot leave — return error with code owner_cannot_leave
- Never expose other circle's data to non-members

When done, list all circle endpoints that are ready to test.
```
