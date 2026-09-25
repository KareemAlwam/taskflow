# TaskFlow — Part 1 of 5: Database Models & Backend Foundation

**Build order: FIRST.** Nothing else works without this. Paste this entire file into omni as-is — it's self-contained, nothing to attach.

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

CORE ENTITIES (do not change these field names — every later part depends on them):
- User: id, name, email (unique), password_hash, created_at, updated_at
- Project: id, name, description, created_by, member_limit (default 20),
  created_at, updated_at, deleted_at (nullable, soft delete)
- ProjectMembership: id, project_id, user_id, role (admin|organizer|member),
  invited_by, status (invited|active|removed), joined_at, created_at.
  Unique index on (project_id, user_id).
- Task: id, project_id, title, description, status (todo|in_progress|blocked|done),
  priority (low|medium|high), assignee_id (REQUIRED — a task can never exist
  without an assignee), created_by, due_date, created_at, updated_at

ROLE RULES (scoped per-project, never global — a user can be admin on Project A
and a plain member on Project B):
- admin: full control, including deleting the project. Auto-granted to whoever
  creates the project. Cannot be removed if they are the last admin (block, 409).
- organizer: can manage members and tasks, cannot delete the project, cannot
  manage/remove/promote admins or organizers.
- member: read-only on everything except they can change the STATUS field
  (only) of tasks assigned to them, and only their own.

AUTH RULE: never put a project role inside the JWT. The JWT only carries
user_id + iat/exp. Role must be resolved fresh on every request by looking up
(user_id, project_id) in ProjectMembership.

ERROR FORMAT (use this shape everywhere in the backend):
{ "error": { "code": "FORBIDDEN", "message": "human readable reason" } }
Use correct status codes: 400 validation, 401 not authenticated, 403 wrong role,
404 not found, 409 conflict (sole-admin, member cap, non-member assignee),
429 rate-limited.

---

## Your task: Part 1 — Database Models & Backend Foundation

Build the foundation of the TaskFlow backend.

1. Project structure:
   ```
   /backend
     /models      (Mongoose schemas)
     /routes
     /controllers
     /middleware
     /config
     server.js
   ```

2. Create Mongoose models for exactly the 4 entities listed in the shared
   context above:
   - `User.js`
   - `Project.js`
   - `ProjectMembership.js` (compound unique index on `project_id` + `user_id`)
   - `Task.js` (`assignee_id` is `required: true` — no task may be saved without one)

3. Add schema-level validation (required fields, enums for role/status/priority,
   unique email on User) and comment WHY each constraint exists — e.g. "role is
   scoped per-membership, not per-user, because a user's permissions differ per
   project."

4. Set up `config/db.js`: Mongoose connection using `process.env.MONGODB_URI`,
   with clear console logging on connect/error, and a `.env.example` file
   listing `MONGODB_URI`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `PORT`.

5. Set up `server.js`: Express app skeleton, JSON body parsing, `cookie-parser`,
   `cors` (credentials: true), a health-check route (`GET /health`), and a
   centralized error-handling middleware that outputs the shared error JSON
   shape above.

6. Write a short `ARCHITECTURE.md` in `/backend` explaining: the folder
   structure, why role is looked up per-request instead of stored in the JWT,
   and how the 4 models relate to each other (one paragraph + a simple
   Mermaid ER diagram in a code block is fine — paste it into mermaid.live to
   preview, no special tool needed).

Do not build any routes yet beyond `/health` — that's Parts 2–4. Comment every
schema field with its purpose. Deliver working, runnable code, not pseudocode.

---

## Before you move to Part 2

- [ ] `npm install` runs clean
- [ ] Server connects to MongoDB (Atlas free tier is fine) and logs success
- [ ] `GET /health` returns 200
- [ ] Save the 4 model files somewhere — you'll attach them to Part 2's prompt
