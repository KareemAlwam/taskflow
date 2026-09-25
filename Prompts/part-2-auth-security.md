# TaskFlow — Part 2 of 5: Auth, Security & Middleware

**Build order: SECOND**, after Part 1. Paste this whole file into omni, then paste/attach your real `User.js` model from Part 1 right after it — the prompt below assumes that model already exists.

---

## Shared context (applies to the whole project)

You are helping build "TaskFlow" — a lightweight TASK MANAGEMENT tool, not a full
project-management suite. Keep scope tight: no Gantt charts, no sprints, no time
tracking, no file attachments unless explicitly asked. The core object the whole
app revolves around is the TASK; Projects and roles exist only to organize and
gate access to tasks.

STACK: HTML, CSS, vanilla JavaScript (frontend) + Node.js, Express, Mongoose,
MongoDB (backend). No frontend framework (no React/Vue) — keep it framework-free
and simple. Use JWT for auth, httpOnly cookies for the refresh token.

DESIGN PRINCIPLE: clean, simple, minimal UI. One accent color, generous
whitespace, system font stack, no UI library — plain CSS only. Prioritize clarity
over decoration.

CODE PRINCIPLE: every file must be commented. Comment the WHY (business rule,
permission reason, edge case) not just the WHAT.

CORE ENTITIES (already built in Part 1 — do not change field names):
- User: id, name, email (unique), password_hash, created_at, updated_at
- Project: id, name, description, created_by, member_limit (default 20),
  created_at, updated_at, deleted_at (nullable, soft delete)
- ProjectMembership: id, project_id, user_id, role (admin|organizer|member),
  invited_by, status (invited|active|removed), joined_at, created_at.
  Unique index on (project_id, user_id).
- Task: id, project_id, title, description, status (todo|in_progress|blocked|done),
  priority (low|medium|high), assignee_id (REQUIRED), created_by, due_date,
  created_at, updated_at

AUTH RULE: never put a project role inside the JWT. The JWT only carries
user_id + iat/exp. Role must be resolved fresh on every request by looking up
(user_id, project_id) in ProjectMembership — that lookup is what Part 3 builds;
your job here is just proving identity, not authorizing actions.

ERROR FORMAT (use this shape everywhere in the backend):
{ "error": { "code": "FORBIDDEN", "message": "human readable reason" } }
Use correct status codes: 400 validation, 401 not authenticated, 403 wrong role,
404 not found, 409 conflict, 429 rate-limited.

**Attach here:** paste your real `models/User.js` file from Part 1 before the task below.

---

## Your task: Part 2 — Auth, Security & Middleware

Build authentication and security middleware for the TaskFlow backend, using
the User model already built (attached above).

1. `/controllers/authController.js` + `/routes/authRoutes.js` implementing:
   - `POST /auth/register` → hash password with bcrypt (cost factor ≥ 10),
     create User, return 201 (never return `password_hash` in any response, ever)
   - `POST /auth/login` → verify bcrypt hash, issue an access token (JWT,
     15 min expiry, payload = `{ user_id, iat, exp }` ONLY) returned in the
     JSON body, and a refresh token (JWT, 7 day expiry) set as an httpOnly,
     secure, sameSite cookie
   - `POST /auth/refresh` → read the refresh cookie, verify it, issue a new
     access token (rotate the refresh token too — reissue a new refresh cookie)
   - `POST /auth/logout` → clear the refresh cookie / invalidate it

2. Password rules at registration: minimum 8 characters + comment on what
   complexity rule you chose and why.

3. `/middleware/auth.js` — `requireAuth` middleware: reads
   `Authorization: Bearer <token>`, verifies it, attaches `req.userId`. Returns
   401 with the shared error format if missing/invalid/expired. Comment
   clearly: this middleware ONLY proves identity, never authorizes an action —
   role checks happen per-route in Part 3 and 4 by querying ProjectMembership.

4. `/middleware/rateLimiter.js` using `express-rate-limit`:
   - a general limiter: 100 requests/minute per IP, applied globally
   - a strict limiter: applied specifically to `/auth/login` (to slow
     brute-force attempts) — export it so Part 3 can also apply it to the
     invite-member endpoint. Return 429 with a `Retry-After` header.

5. Write 3–4 lines of comments in each file explaining the security reasoning
   (e.g. why the refresh token lives in an httpOnly cookie and not
   localStorage, why access tokens are short-lived).

Do not build project/task routes — that's Parts 3 and 4. Export `requireAuth`
and both rate limiters so the other parts can import them. Deliver working,
runnable code, not pseudocode.

---

## Before you move to Part 3

- [ ] Register a test user, then log in — confirm you get an access token + a
      `Set-Cookie` refresh token
- [ ] Hit a protected dummy route with an expired/missing token → confirm 401
- [ ] Hammer `/auth/login` past the limit → confirm 429 with `Retry-After`
- [ ] Save `middleware/auth.js` and `middleware/rateLimiter.js` — you'll attach
      them (plus the Part 1 models) to Part 3's prompt
