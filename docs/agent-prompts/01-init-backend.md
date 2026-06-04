# CircleStream — Initial Agent Prompt

Paste prompt ini ke AI agent kamu (Antigravity) untuk memulai project dari nol.

---

## Prompt

```
You are a senior backend engineer helping me build CircleStream — a private real-time photo sharing app for small friend groups.

Before doing anything, read ALL documents in the docs/ folder in this exact order:
1. docs/00-project-overview.md
2. docs/01-product-requirements-document.md
3. docs/04-domain-model.md
4. docs/02-system-architecture.md
5. docs/03-tech-stack-decision.md
6. docs/backend/01-database-schema.md
7. docs/backend/02-api-specification.md
8. docs/backend/08-authentication.md
9. docs/backend/09-security-model.md
10. docs/backend/06-r2-storage.md
11. docs/backend/07-upstash-reactions.md
12. docs/backend/05-realtime-events.md
13. docs/implementation/01-backend-folder-structure.md
14. docs/implementation/02-database-migrations.md
15. docs/implementation/03-api-checklist.md
16. docs/roadmap/05-product-principles.md

After reading all documents, do the following:

---

## TASK: Setup Monorepo + Backend Project Structure

### 1. Connect to GitHub remote
The repo already exists at: https://github.com/farizziezhi/circlestream
Run:
git remote add origin https://github.com/farizziezhi/circlestream.git
git checkout -b main

### 2. Create monorepo root structure
Create these files at root level:
- .gitignore (cover Go, Flutter, .env, IDE files)
- README.md (simple, just project name + stack + folder structure)

### 3. Initialize backend project
Create the full backend folder structure exactly as described in docs/implementation/01-backend-folder-structure.md under a folder named backend/

Run:
cd backend
go mod init github.com/farizziezhi/circlestream/backend

Create all folders and placeholder files (empty files with package declaration are fine for now).

### 4. Create .env.example
Based on docs/backend/08-authentication.md and other backend docs, create backend/.env.example with all required environment variables. Do NOT create .env — the developer will fill that manually.

### 5. Create .gitignore for backend
Make sure backend/.env is never committed.

---

## COMMIT RULES — FOLLOW STRICTLY

After completing each logical unit of work, commit immediately. Do not batch multiple unrelated things into one commit.

Use conventional commit format:
- feat: add something new
- chore: setup, config, scaffolding
- fix: bug fix
- docs: documentation only
- refactor: restructure without behavior change
- test: add or update tests

Examples:
- chore: init monorepo structure
- chore: init golang backend project
- chore: add backend folder structure scaffold
- chore: add .env.example with all required variables

Push after every commit:
git add .
git commit -m "chore: your message here"
git push origin main

---

## RULES
- Never commit .env files
- Never skip a commit — every completed task must be committed before moving to the next
- Follow folder structure exactly as in docs/implementation/01-backend-folder-structure.md
- Follow naming conventions: snake_case files, PascalCase structs, camelCase variables
- All code must be in English, all comments in English
- Do not implement business logic yet — this task is structure and scaffold only

When done, confirm what was created and what the next step should be.
```
