# CircleStream
**Real-Time, Raw, and Intimate Photo Stream.**

---

## What Is CircleStream

CircleStream adalah aplikasi mobile private photo sharing untuk kelompok kecil teman dekat.

**Prinsip utama:**
- Private by default
- Camera first
- Real-time
- No followers
- No public feed
- No comments
- No algorithms

---

## Technology Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter |
| Backend | Golang + Fiber |
| Database | Turso (SQLite edge) |
| Storage | Cloudflare R2 |
| Real-time | Ably |
| Cache | Upstash Redis |

---

## Read Order For AI Agents

**IMPORTANT: Read documents in this exact order.**

### Product
1. `docs/00-project-overview.md`
2. `docs/01-product-requirements-document.md`
3. `docs/04-domain-model.md`

### Architecture
4. `docs/02-system-architecture.md`
5. `docs/03-tech-stack-decision.md`

### Backend
6. `docs/backend/01-database-schema.md`
7. `docs/backend/02-api-specification.md`
8. `docs/backend/08-authentication.md`
9. `docs/backend/09-security-model.md`
10. `docs/backend/06-r2-storage.md`
11. `docs/backend/07-upstash-reactions.md`
12. `docs/backend/05-realtime-events.md`

### Frontend
13. `docs/frontend/01-design-system.md`
14. `docs/frontend/02-information-architecture.md`
15. `docs/frontend/03-screen-list.md`
16. `docs/frontend/04-user-flows.md`
17. `docs/frontend/05-app-size-optimization.md`
18. `docs/frontend/06-state-management.md`
19. `docs/frontend/07-flutter-folder-structure.md`
20. `docs/frontend/08-api-integration.md`
21. `docs/frontend/09-realtime-integration.md`

### Implementation
21. `docs/implementation/01-backend-folder-structure.md`
22. `docs/implementation/02-database-migrations.md`
23. `docs/implementation/03-api-checklist.md`
24. `docs/implementation/04-testing-strategy.md`
25. `docs/implementation/05-deployment.md`

### Roadmap
26. `docs/roadmap/01-mvp.md`
27. `docs/roadmap/02-v1.md`
28. `docs/roadmap/03-v2.md`
29. `docs/roadmap/05-product-principles.md`

---

## Implementation Priority

**Phase 1 — Foundation**
- Database schema + migrations
- Auth (register, login, refresh, logout)
- Circle (create, join, leave, members)

**Phase 2 — Content**
- Upload (presign, R2, finalize)
- Feed (list posts, pagination)

**Phase 3 — Engagement**
- Reactions (emoji, counter, Ably)
- Real-time events (post_created, reaction_added)

**Phase 4 — Release**
- Testing (unit + integration)
- Deployment (Railway, Turso, R2)

---

## Non-Negotiable Rules

1. Upload must go **directly** to Cloudflare R2
2. Backend must remain **stateless**
3. Real-time handled by **Ably** only
4. Reaction counters handled by **Upstash Redis**
5. **Photos only** — no video in MVP
6. **No gallery upload** — camera only
7. **No public content** — private circles only
8. **Maximum 10 members** per circle
9. **Camera-first** UX
10. **Simplicity** over feature count

---

## Quick Start

### Backend

```bash
cd circlestream-backend
cp .env.example .env
# Fill in your .env values
go mod tidy
make run
```

### Frontend

```bash
cd circlestream-flutter
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8080/v1
```

---

## Project Structure

```
circlestream/
├── README.md                      ← You are here
├── docs/
│   ├── 00-project-overview.md
│   ├── 01-product-requirements-document.md
│   ├── 02-system-architecture.md
│   ├── 03-tech-stack-decision.md
│   ├── 04-domain-model.md
│   ├── backend/
│   │   ├── 01-database-schema.md
│   │   ├── 02-api-specification.md
│   │   ├── 05-realtime-events.md
│   │   ├── 06-r2-storage.md
│   │   ├── 07-upstash-reactions.md
│   │   ├── 08-authentication.md
│   │   └── 09-security-model.md
│   ├── frontend/
│   │   ├── 01-design-system.md
│   │   ├── 02-information-architecture.md
│   │   ├── 03-screen-list.md
│   │   ├── 04-user-flows.md
│   │   ├── 06-state-management.md
│   │   ├── 07-flutter-folder-structure.md
│   │   ├── 08-api-integration.md
│   │   └── 09-realtime-integration.md
│   ├── implementation/
│   │   ├── 01-backend-folder-structure.md
│   │   ├── 02-database-migrations.md
│   │   ├── 03-api-checklist.md
│   │   ├── 04-testing-strategy.md
│   │   └── 05-deployment.md
│   └── roadmap/
│       ├── 01-mvp.md
│       ├── 02-v1.md
│       ├── 03-v2.md
│       ├── 04-monetization.md
│       └── 05-product-principles.md
├── circlestream-backend/          ← Golang API (separate repo)
└── circlestream-flutter/          ← Flutter app (separate repo)
```
