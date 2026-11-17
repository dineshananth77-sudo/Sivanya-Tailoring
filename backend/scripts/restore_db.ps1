# Database Restore Script for Stitch & Style
param (
    [Parameter(Mandatory=$true)]
    [string]$BackupFile,
    [string]$DbHost = "127.0.0.1",
    [int]$DbPort = 5433,
    [string]$DbUser = "stitch_admin",
    [string]$DbName = "stitch_style_db"
)

if (!(Test-Path -Path $BackupFile)) {
    Write-Host "Error: Backup file not found at $BackupFile" -ForegroundColor Red
    exit 1
}

Write-Host "Restoring $DbName from $BackupFile..." -ForegroundColor Cyan

$env:PGPASSWORD = "StitchStyleSecure2026!Db"
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h $DbHost -p $DbPort -U $DbUser -d $DbName -f $BackupFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "Restore completed successfully!" -ForegroundColor Green
} else {
    Write-Host "Restore failed with exit code $LASTEXITCODE" -ForegroundColor Red
}
