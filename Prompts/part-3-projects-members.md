# TaskFlow — Part 3 of 5: Projects & Members API (incl. email invites)

**Build order: THIRD**, after Parts 1 and 2. Paste this whole file into omni, then attach your real model files from Part 1 and `middleware/auth.js` + `middleware/rateLimiter.js` from Part 2 — the prompt below assumes those already exist.

---

## Shared context (applies to the whole project)

You are helping build "TaskFlow" — a lightweight TASK MANAGEMENT tool, not a full
project-management suite. Keep scope tight: no Gantt charts, no sprints, no time
tracking, no file attachments unless explicitly asked. The core object the whole
app revolves around is the TASK; Projects and roles exist only to organize and
gate access to tasks.

STACK: HTML, CSS, vanilla JavaScript (frontend) + Node.js, Express, Mongoose,
MongoDB (backend). Use JWT for auth, httpOnly cookies for the refresh token.

DESIGN PRINCIPLE: clean, simple, minimal UI (frontend comes in Part 5).

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

ROLE RULES (scoped per-project, never global):
- admin: full control, including deleting the project. Auto-granted to whoever
  creates the project. Cannot be removed if they are the last admin (block, 409).
- organizer: can manage members and tasks, cannot delete the project, cannot
  manage/remove/promote admins or organizers.
- member: read-only except changing status of their own assigned tasks
  (that endpoint is built in Part 4, not here).

ERROR FORMAT (use everywhere):
{ "error": { "code": "FORBIDDEN", "message": "human readable reason" } }
Status codes: 400 validation, 401 not authenticated, 403 wrong role, 404 not
found, 409 conflict (sole-admin, member cap, non-member assignee), 429 rate-limited.

**Attach here:** paste your real model files from Part 1, and `middleware/auth.js` +
`middleware/rateLimiter.js` from Part 2, before the task below.

---

## Your task: Part 3 — Projects & Members API

Build the Projects and Project-Members API for TaskFlow, importing
`requireAuth` and the rate limiters from Part 2 and the models from Part 1
(all attached above).

1. `/middleware/requireRole.js` — a reusable middleware factory
   `requireRole(...allowedRoles)` that: looks up `ProjectMembership` for
   `(req.userId, req.params.id)`, rejects with 403 if the membership doesn't
   exist, is `status !== 'active'`, or its role isn't in `allowedRoles`. Attach
   the resolved role to `req.projectRole` so downstream handlers (Part 4) can
   use it.

2. `/routes/projectRoutes.js` + `/controllers/projectController.js`:
   - `POST   /projects` — any authenticated user → creates a Project AND a
     ProjectMembership row (role: admin, status: active) for the creator, in
     the same step. Comment why this must happen atomically.
   - `GET    /projects` — list only projects where the user has an active
     membership.
   - `GET    /projects/:id` — `requireRole(admin, organizer, member)`. If the
     caller's membership status is `invited`, flip it to `active` and set
     `joined_at` here (viewing/logging into the project counts as accepting
     the invite), then continue.
   - `PUT    /projects/:id` — `requireRole(admin)` only.
   - `DELETE /projects/:id` — `requireRole(admin)` only. Soft delete: set
     `deleted_at`, don't remove the document. Exclude soft-deleted projects
     from all list/get queries.

3. `/routes/memberRoutes.js` + `/controllers/memberController.js`:
   - `GET    /projects/:id/members` — `requireRole(admin, organizer, member)` —
     list members with their role and status.
   - `POST   /projects/:id/members` — `requireRole(admin, organizer)` + the
     strict rate limiter from Part 2. Body: `{ email }`.
     - If `member_limit` is already reached → 409.
     - If the email belongs to an existing User → create a ProjectMembership
       with `status: invited`, send an email notification.
     - If no account exists for that email → send a signup-invite email with
       a link; when that person registers, auto-create their
       ProjectMembership (`status: invited`).
     - Use `nodemailer`; stub the actual SMTP transport with clear TODO
       comments and env vars (`SMTP_HOST`, etc.) so it can be pointed at
       Mailtrap in dev and a real provider in prod.
   - `PATCH  /projects/:id/members/:userId` — `requireRole(admin)` only. Body:
     `{ role }`. Block demoting/removing the sole remaining admin (409).
   - `DELETE /projects/:id/members/:userId` — `requireRole(admin, organizer)`,
     but an organizer may NOT remove an admin (403 if they try). Before
     removing, check if the member has any tasks assigned with
     `status !== 'done'`; if so, return 409 and require reassignment first
     (don't auto-unassign — comment why: silent unassignment hides work from
     view).

Comment every handler with which role(s) can call it and the one-line
business reason. Deliver working, runnable code, not pseudocode.

---

## Before you move to Part 4

- [ ] Create a project as User A → confirm they're auto-admin
- [ ] Invite User B by email → confirm `status: invited`, then log in as B and
      view the project → confirm it flips to `active`
- [ ] Try removing the sole admin → confirm 409
- [ ] Save `middleware/requireRole.js` — Part 4 needs it too
