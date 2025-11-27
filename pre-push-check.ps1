# Pre-push Security Check Script (PowerShell)
# Run this before pushing to GitHub

Write-Host "
 Running security checks before GitHub push..." -ForegroundColor Cyan
Write-Host ""

$ISSUES = 0

# Check for sensitive strings
Write-Host "Checking for API keys and passwords..." -ForegroundColor Yellow

# Check for Firebase API key
if (git grep "AIzaSyAt05j02Wh4711p8EZb4hc7RFz1i42rUzc" 2>$null) {
    Write-Host " FOUND: Firebase API key in tracked files!" -ForegroundColor Red
    $ISSUES++
} else {
    Write-Host " No Firebase API keys found" -ForegroundColor Green
}

# Check for MongoDB password
if (git grep "SKLpVgXjQLo1LbnP" 2>$null) {
    Write-Host " FOUND: MongoDB password in tracked files!" -ForegroundColor Red
    $ISSUES++
} else {
    Write-Host " No MongoDB passwords found" -ForegroundColor Green
}

# Check for MongoDB username
if (git grep "amirmahdi82sf" 2>$null) {
    Write-Host " FOUND: MongoDB username in tracked files!" -ForegroundColor Red
    $ISSUES++
} else {
    Write-Host " No MongoDB usernames found" -ForegroundColor Green
}

# Check for sensitive files
Write-Host "
Checking for sensitive files in staging area..." -ForegroundColor Yellow

$trackedFiles = git ls-files 2>$null

if ($trackedFiles -match "server/\.env$") {
    Write-Host " FOUND: server/.env in staging area!" -ForegroundColor Red
    $ISSUES++
} else {
    Write-Host " server/.env not tracked" -ForegroundColor Green
}

if ($trackedFiles -match "lib/firebase_options\.dart$") {
    Write-Host " FOUND: lib/firebase_options.dart in staging area!" -ForegroundColor Red
    $ISSUES++
} else {
    Write-Host " lib/firebase_options.dart not tracked" -ForegroundColor Green
}

if ($trackedFiles -match "android/app/google-services\.json$") {
    Write-Host " FOUND: android/app/google-services.json in staging area!" -ForegroundColor Red
    $ISSUES++
} else {
    Write-Host " android/app/google-services.json not tracked" -ForegroundColor Green
}

# Final verdict
Write-Host ""
if ($ISSUES -eq 0) {
    Write-Host " All checks passed! Safe to push to GitHub." -ForegroundColor Green
    exit 0
} else {
    Write-Host " Found $ISSUES security issue(s). DO NOT PUSH!" -ForegroundColor Red
    Write-Host "Please remove sensitive data before pushing." -ForegroundColor Red
    exit 1
}
