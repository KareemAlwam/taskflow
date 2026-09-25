# TaskFlow

TaskFlow is a static frontend with an Express/MongoDB backend for projects, members, invitations, and tasks.

## Structure

- `backend/` Express API, MongoDB models, authentication, invitations, and email service
- `frontendV2/frontend/` static HTML/CSS/JavaScript frontend
- `Prompts/` project planning and implementation prompts

## Local setup

1. Copy `backend/.env.example` to `backend/.env`.
2. Fill in MongoDB, JWT, SMTP, and frontend-origin values.
3. Install backend dependencies:

```bash
cd backend
npm install
npm start
```

4. Serve the frontend from the frontend directory:

```bash
python3 -m http.server 8000 --directory frontendV2/frontend
```

Open `http://localhost:8000/auth.html`.

## Windows quick start

1. Make sure Node.js, npm, Python, and MongoDB access are available.
2. Double-click `start-project.bat`.
3. Open `http://localhost:8000/auth.html`.

The Windows launcher installs backend dependencies automatically when needed and opens separate windows for the API and frontend.

Never share `backend/.env`, database credentials, SMTP credentials, or JWT secrets.
