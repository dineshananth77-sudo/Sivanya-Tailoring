@echo off
setlocal

echo ===================================================
echo   Stitch & Style Production API Service Launcher
echo ===================================================

cd /d "%~dp0.."

if not exist ".env" (
    echo [ERROR] .env file not found! Please create one from .env.example.
    exit /b 1
)

echo [1/2] Running database migrations...
call ".\venv\Scripts\alembic.exe" upgrade head
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Migration failed. Aborting startup.
    exit /b %ERRORLEVEL%
)

echo [2/2] Starting Uvicorn production server on http://0.0.0.0:8000...
call ".\venv\Scripts\uvicorn.exe" app.main:app --host 0.0.0.0 --port 8000 --workers 2

endlocal
