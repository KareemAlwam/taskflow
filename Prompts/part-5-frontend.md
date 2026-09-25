# TaskFlow — Part 5 of 5: Frontend (HTML/CSS/JS)

**Build order: LAST**, after Parts 1–4 all work and are tested. Paste this whole file into omni, then attach your real, finished route files from Parts 2–4 (auth routes, project/member routes, task routes) — the prompt below assumes the real API already exists and works.

---

## Shared context (applies to the whole project)

You are helping build "TaskFlow" — a lightweight TASK MANAGEMENT tool, not a
full project-management suite. The core object is the TASK; Projects and roles
exist only to organize and gate access to tasks.

STACK: plain HTML, CSS, and vanilla JavaScript. No framework (no React/Vue) —
keep it simple and dependency-free.

DESIGN PRINCIPLE: clean, simple, minimal UI. One accent color, generous
whitespace, system font stack, no CSS/UI library. Prioritize clarity over
decoration. Mobile-responsive.

CODE PRINCIPLE: comment every JS file with which backend endpoints it calls
and which role(s) should see which UI elements — but be explicit in comments
that hiding a button client-side is a UX nicety ONLY. The real enforcement is
server-side (Parts 3 and 4); the frontend must never be treated as the source
of truth for permissions.

ROLE RULES (for showing/hiding UI — actual enforcement already lives in the
backend you're calling):
- admin: sees everything, can edit project info, manage members/roles, manage
  all tasks.
- organizer: can manage members and tasks, cannot delete the project or
  manage admins/organizers.
- member: read-only everywhere except a status dropdown on tasks assigned to
  them.

AUTH FLOW: login returns a short-lived access token in the JSON body (keep it
in memory only — a JS variable, NOT localStorage; comment why: XSS risk) and
sets an httpOnly refresh cookie automatically. Every fetch() must include
`credentials: 'include'` and an `Authorization: Bearer <token>` header. On a
401, call `POST /auth/refresh` once, then retry the original request before
giving up and redirecting to the login page.

**Attach here:** paste your real, working route files from Parts 2 (auth),
3 (projects/members), and 4 (tasks) before the task below, so the model wires
up the exact endpoints and payload shapes you actually built.

---

## Your task: Part 5 — Frontend

Build the TaskFlow frontend end to end, wired to the real backend endpoints
attached above.

Pages / user flow, in this exact order:

1. **auth.html** — login and create-account forms (two tabs on one page, or
   two pages — your call). On successful login, store the access token in
   memory and redirect to `home.html`. Handle the refresh-then-retry flow
   described above on any 401.

2. **home.html** — after login, shows:
   - a grid/list of every project the user belongs to (`GET /projects`), each
     card showing the project name, description, and the user's role badge
     on that project (admin/organizer/member)
   - a "New Project" button (any authenticated user can create one)
   - clicking a project card goes to `project.html?id=...`

3. **project.html** — the project detail page. Shows:
   - project name/description (editable inline only if the viewer is admin)
   - a "Members" section: list of members + their role. If the viewer is
     admin or organizer, show an "Invite by email" input + button; for
     admins only, show role-change / remove controls next to each member
   - a "Tasks" section: list of all tasks (title, assignee name, status
     badge, priority badge). If the viewer is admin/organizer, show a
     "New Task" button and edit/delete icons. Every user, regardless of
     role, can click a task to open `task.html?id=...`

4. **task.html** — task detail page. Shows all task fields read-only for
   everyone.
   - If the viewer is admin/organizer: full edit form (all fields) + delete.
   - If the viewer is a plain member AND is the assignee: show ONLY a status
     dropdown (todo/in_progress/blocked/done) that PATCHes
     `/projects/:id/tasks/:taskId/status` with just `{ status }` — no other
     field editable.
   - If the viewer is a plain member and NOT the assignee: fully read-only,
     no controls at all.

Structure:
```
/frontend
  auth.html, home.html, project.html, task.html
  /css/style.css
  /js/api.js       (one shared fetch wrapper: attaches auth header, handles
                     401 → refresh → retry, throws a typed error using the
                     backend's { error: { code, message } } shape)
  /js/auth.js, home.js, project.js, task.js  (one per page)
```

Use badges/colors for role and status (color + text label together, not color
alone). Handle and display errors from the backend's `{ error: { code,
message } }` shape in a simple toast/banner, not a raw alert(). Deliver
working, runnable code, not pseudocode — this should open in a browser and
actually work against the real backend.

---

## Final check (whole app)

- [ ] Register → login → land on home → see your project
- [ ] Create a project → auto-admin → invite a second (real or test) account
- [ ] As admin: create a task, assign it to the invited user
- [ ] Log in as the invited user: see the task, change only its status,
      confirm you can't edit anything else and can't see other projects
- [ ] Confirm a 401 triggers a silent refresh, not an immediate logout
