# TaskFlow — Part 4 of 5: Tasks API (the core feature — build carefully)

**Build order: FOURTH**, after Parts 1–3. Paste this whole file into omni, then attach your real model files from Part 1, `middleware/auth.js` from Part 2, and `middleware/requireRole.js` from Part 3 — the prompt below assumes those already exist.

---

## Shared context (applies to the whole project)

You are helping build "TaskFlow" — a lightweight TASK MANAGEMENT tool, not a full
project-management suite. The core object the whole app revolves around is the
TASK; Projects and roles exist only to organize and gate access to tasks. This
part is the most important one in the whole product.

CORE ENTITIES (already built in Part 1 — do not change field names):
- User: id, name, email (unique), password_hash, created_at, updated_at
- Project: id, name, description, created_by, member_limit, created_at,
  updated_at, deleted_at
- ProjectMembership: id, project_id, user_id, role (admin|organizer|member),
  invited_by, status (invited|active|removed), joined_at, created_at
- Task: id, project_id, title, description, status (todo|in_progress|blocked|done),
  priority (low|medium|high), assignee_id (REQUIRED — never null), created_by,
  due_date, created_at, updated_at

ROLE RULES (scoped per-project, never global):
- admin / organizer: can create, edit, delete, and reassign any task.
- member: read-only on everything except they can change the STATUS field
  (only) of tasks assigned to them, and only their own. This is the single
  most important permission boundary in the app — build it carefully.

CODE PRINCIPLE: comment the WHY, not just the WHAT — especially on the status
endpoint below.

ERROR FORMAT (use everywhere):
{ "error": { "code": "FORBIDDEN", "message": "human readable reason" } }
Status codes: 400 validation, 401 not authenticated, 403 wrong role, 404 not
found, 409 conflict, 429 rate-limited.

**Attach here:** paste your real model files from Part 1, `middleware/auth.js`
from Part 2, and `middleware/requireRole.js` from Part 3, before the task below.

---

## Your task: Part 4 — Tasks API

Build the Tasks API for TaskFlow, nested under `/projects/:id/tasks`, importing
`requireAuth`, `requireRole`, and the models already built (attached above).

- `POST   /projects/:id/tasks`
  `requireRole(admin, organizer)`. Body must include `assignee_id`. Validate
  the assignee is an ACTIVE member of this project — if not, 400.
  `created_by = req.userId`.

- `GET    /projects/:id/tasks`
  `requireRole(admin, organizer, member)`. Everyone with any active
  membership can see the full task list for the project — this is
  intentional. Comment that explicitly so it's not "fixed" later by mistake.

- `GET    /projects/:id/tasks/:taskId`
  Same access as above (any active member).

- `PUT    /projects/:id/tasks/:taskId`
  `requireRole(admin, organizer)` only. Can edit any field including
  reassigning — if `assignee_id` changes, re-validate the new assignee is an
  active member (400 if not).

- `DELETE /projects/:id/tasks/:taskId`
  `requireRole(admin, organizer)` only.

- `PATCH  /projects/:id/tasks/:taskId/status`
  *** This is the one endpoint a plain "member" role is allowed to call. ***
  Build custom authorization here (don't just reuse `requireRole`) because the
  rule is: admin/organizer can always call it, OR the caller is a member AND
  `task.assignee_id === req.userId`. Reject with 403 if neither is true.
  Additionally: this endpoint may ONLY change the `status` field — if the
  request body contains any other field, respond 400 (don't silently ignore
  extra fields; the frontend in Part 5 depends on this being a hard error so
  it can't accidentally leak permission). Comment this rule loudly.

Write a short `TASKS.md` summarizing: the status enum's meaning (todo →
in_progress → blocked/done are the expected transitions, but don't hard-block
"illegal" transitions server-side — note it as a v2 TODO instead), and a table
of which role can call which endpoint. Deliver working, runnable code, not
pseudocode.

---

## Before you move to Part 5

- [ ] As admin/organizer: create a task, edit it, reassign it, delete it — all work
- [ ] As a member who IS the assignee: PATCH status alone → succeeds; PATCH
      with `{ status, title }` → 400
- [ ] As a member who is NOT the assignee: any write attempt → 403
- [ ] Save the full set of task routes — you'll attach them to Part 5's prompt
