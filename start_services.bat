@echo off
title Stitch & Style - Local Services Launcher
cd /d "%~dp0"

echo ========================================================
echo   Starting Stitch ^& Style Services (PostgreSQL + FastAPI)
echo ========================================================
echo.

:: 1. Clean stale postmaster.pid if postgres is not active
if exist "pgdata\postmaster.pid" (
    del /f /q "pgdata\postmaster.pid" >nul 2>&1
)

:: 2. Launch PostgreSQL on port 5433 in background
echo [1/2] Starting PostgreSQL on port 5433...
start "PostgreSQL (Port 5433)" /min "C:\Program Files\PostgreSQL\18\bin\postgres.exe" -D "%~dp0pgdata"

:: Wait 3 seconds for PostgreSQL to initialize
timeout /t 3 /nobreak >nul

:: 3. Launch FastAPI backend on port 8000
echo [2/2] Starting FastAPI Backend on http://127.0.0.1:8000 ...
cd backend
.\venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
