@echo off
setlocal

set DB_HOST=127.0.0.1
set DB_PORT=5433
set DB_USER=stitch_admin
set DB_NAME=stitch_style_db
set PGPASSWORD=StitchStyleSecure2026!Db

if "%~1"=="" (
    echo [ERROR] Usage: restore_db.bat ^<path_to_backup_file.sql^>
    exit /b 1
)

set BACKUP_FILE=%~1

if not exist "%BACKUP_FILE%" (
    echo [ERROR] Backup file not found: %BACKUP_FILE%
    exit /b 1
)

echo [INFO] Restoring %DB_NAME% from %BACKUP_FILE%...
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f "%BACKUP_FILE%"

if %ERRORLEVEL% equ 0 (
    echo [SUCCESS] Database restored successfully!
) else (
    echo [ERROR] Restore failed with error code %ERRORLEVEL%
)

endlocal
