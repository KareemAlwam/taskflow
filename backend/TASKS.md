# TaskFlow — Tasks API Documentation

## Overview

Tasks are the core feature of TaskFlow. Everything else — projects, members, roles — exists to organize and gate access to tasks. This document describes the task status workflow and the permission model for task endpoints.

## Task Status Enum

The `status` field tracks a task's workflow state. Valid values:

- **`todo`** — Not started yet. The default state for newly created tasks.
- **`in_progress`** — Actively being worked on by the assignee(s).
- **`blocked`** — Waiting on something external (another task, a dependency, a decision, etc.) before work can continue.
- **`done`** — Completed.

### Expected Transitions

The typical workflow is: `todo` → `in_progress` → `done`

A task can move to `blocked` from `todo` or `in_progress` if it hits a dependency, then back to `in_progress` once unblocked.

**Note:** The API does not enforce transition rules server-side (e.g., you CAN jump from `todo` directly to `done`). This is intentional to avoid blocking edge cases. Validating workflow rules is tracked as a v2 enhancement (TODO).

## Permission Model — Who Can Do What

| Endpoint | Admin | Organizer | Member | Notes |
|----------|-------|-----------|--------|-------|
| `POST /projects/:id/tasks` | ✅ | ✅ | ❌ | Create a new task. Must provide at least one active assignee. |
| `GET /projects/:id/tasks` | ✅ | ✅ | ✅ | List all tasks in the project. **Intentional:** even plain members can see all tasks, not just their own. |
| `GET /projects/:id/tasks/:taskId` | ✅ | ✅ | ✅ | View one task. Same visibility as list. |
| `PUT /projects/:id/tasks/:taskId` | ✅ | ✅ | ❌ | Edit any field, including reassigning. |
| `DELETE /projects/:id/tasks/:taskId` | ✅ | ✅ | ❌ | Delete a task. |
| `PATCH /projects/:id/tasks/:taskId/status` | ✅ | ✅ | ⚠️ Conditional | **Special case:** admin/organizer can always call it. A member can call it ONLY if they are assigned to the task. |

### Critical Rule: PATCH /status Endpoint

This is the **only** endpoint a plain "member" role is allowed to call for write operations.

**Authorization logic:**
- Admin or organizer → always allowed (any task, any status change)
- Member → allowed ONLY if `task.assignee_ids` includes `req.userId`

**Field restriction:**
- This endpoint accepts ONLY a `status` field in the request body.
- If the body contains ANY other field (e.g., `title`, `description`, `assignee_ids`), the API responds with **400 Bad Request**.
- This is a hard error, not silently ignored, so the frontend cannot accidentally leak permission beyond what a member should have.

## Assignee Validation

When creating or updating a task, every user in `assignee_ids` must be an **active** member of the project:
- Status must be `'active'` (not `'invited'` or `'removed'`)
- The membership must exist in the `ProjectMembership` collection

If validation fails, the API responds with **400 Bad Request** and names the invalid assignee.

## Examples

### Create a task (admin/organizer only)
```http
POST /api/projects/507f1f77bcf86cd799439011/tasks
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "title": "Implement user search",
  "description": "Add full-text search to the users table",
  "assignee_ids": ["507f191e810c19729de860ea"],
  "due_date": "2026-10-15T17:00:00.000Z",
  "priority": "high",
  "status": "todo"
}
```

### Update task status as a member (assigned to you)
```http
PATCH /api/projects/507f1f77bcf86cd799439011/tasks/507f191e810c19729de860eb/status
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "status": "in_progress"
}
```

### Update task status with extra fields (rejected)
```http
PATCH /api/projects/507f1f77bcf86cd799439011/tasks/507f191e810c19729de860eb/status
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "status": "done",
  "title": "Updated title"
}

→ 400 Bad Request
{
  "error": {
    "code": "INVALID_FIELDS",
    "message": "This endpoint only accepts \"status\". Remove these fields: title"
  }
}
```

## Design Decisions

1. **All members can see all tasks** — TaskFlow is a lightweight collaborative tool where transparency is the default. This is intentional, not a permission bug.

2. **Status-only endpoint for members** — Giving members a separate, restricted endpoint prevents accidental permission escalation. The hard validation (400 on extra fields) ensures the frontend can't accidentally send a write that changes more than status.

3. **No server-side workflow validation** — Not enforcing transitions (e.g., blocking "todo → done") keeps the API flexible for edge cases. Stricter validation is a v2 enhancement.

4. **Required assignees** — Every task must have at least one assignee. Tasks are never orphaned or unowned. Assignees must be active members at creation/update time.
