@echo off
setlocal
cd /d "%~dp0"

if not exist "backend\.env" (
  echo backend\.env is missing. Copy backend\.env.example to backend\.env and fill in the values.
  pause
  exit /b 1
)

start "TaskFlow Backend" cmd /k "cd /d "%~dp0backend" && if not exist node_modules npm install && npm start"
start "TaskFlow Frontend" cmd /k "cd /d "%~dp0" && py -m http.server 8000 --directory frontendV2/frontend"

echo TaskFlow is starting.
echo Open http://localhost:8000/auth.html
