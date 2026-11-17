# Database Backup Script for Stitch & Style
param (
    [string]$DbHost = "127.0.0.1",
    [int]$DbPort = 5433,
    [string]$DbUser = "stitch_admin",
    [string]$DbName = "stitch_style_db",
    [string]$BackupDir = "$PSScriptRoot\..\backups"
)

if (!(Test-Path -Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputFile = "$BackupDir\${DbName}_backup_${Timestamp}.sql"

Write-Host "Creating backup of $DbName to $OutputFile..." -ForegroundColor Cyan

$env:PGPASSWORD = "StitchStyleSecure2026!Db"
& "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe" -h $DbHost -p $DbPort -U $DbUser -d $DbName -F p -f $OutputFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "Backup completed successfully! Saved at $OutputFile" -ForegroundColor Green
} else {
    Write-Host "Backup failed with exit code $LASTEXITCODE" -ForegroundColor Red
}
