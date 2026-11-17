@echo off
setlocal

set DB_HOST=127.0.0.1
set DB_PORT=5433
set DB_USER=stitch_admin
set DB_NAME=stitch_style_db
set PGPASSWORD=StitchStyleSecure2026!Db
set BACKUP_DIR=%~dp0..\backups

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

for /f %%a in ('powershell -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TIMESTAMP=%%a
set OUTPUT_FILE=%BACKUP_DIR%\%DB_NAME%_backup_%TIMESTAMP%.sql

echo [INFO] Creating backup of %DB_NAME% to %OUTPUT_FILE%...
"C:\Program Files\PostgreSQL\18\bin\pg_dump.exe" -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -F p -f "%OUTPUT_FILE%"

if %ERRORLEVEL% equ 0 (
    echo [SUCCESS] Backup completed: %OUTPUT_FILE%
) else (
    echo [ERROR] Backup failed with error code %ERRORLEVEL%
)

endlocal
