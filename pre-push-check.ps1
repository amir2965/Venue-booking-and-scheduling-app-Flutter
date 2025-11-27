# Pre-push Security Check Script (PowerShell)
# Run this before pushing to GitHub

Write-Host "
 Running security checks before GitHub push..." -ForegroundColor Cyan
Write-Host ""

$ISSUES = 0

# Check for common sensitive patterns
Write-Host "Checking for sensitive data patterns..." -ForegroundColor Yellow

# Check for .env files (should not be tracked)
$envFiles = git ls-files | Select-String "\.env$" | Where-Object { $_ -notmatch "\.env\.example" }
if ($envFiles) {
    Write-Host " FOUND: .env files in tracked files!" -ForegroundColor Red
    $envFiles | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
    $ISSUES++
} else {
    Write-Host " No .env files tracked" -ForegroundColor Green
}

# Check for common credential patterns
$patterns = @(
    @{Name="Firebase API Keys"; Pattern="AIzaSy[A-Za-z0-9_-]{33}"},
    @{Name="MongoDB connection strings"; Pattern="mongodb(\+srv)?://[^/\s]+"},
    @{Name="Generic passwords"; Pattern='password["\s]*[:=]["\s]*[^"\s]{8,}'},
    @{Name="API keys"; Pattern='api[_-]?key["\s]*[:=]["\s]*["\''"][^"\''"\s]{20,}'}
)

foreach ($check in $patterns) {
    Write-Host "  Checking for $($check.Name)..." -ForegroundColor Gray
    $results = git grep -iE "$($check.Pattern)" 2>$null | 
        Where-Object { 
            $_ -notmatch "\.example" -and 
            $_ -notmatch "YOUR_" -and
            $_ -notmatch "your-" -and
            $_ -notmatch "password\s*=\s*null" -and
            $_ -notmatch "# " -and
            $_ -notmatch "//"
        }
    
    if ($results) {
        Write-Host "      Potential $($check.Name.ToLower()) found:" -ForegroundColor Yellow
        $results | Select-Object -First 3 | ForEach-Object { 
            Write-Host "       $_" -ForegroundColor Yellow 
        }
        $ISSUES++
    }
}

# Check for sensitive files
Write-Host "
Checking for sensitive files in staging area..." -ForegroundColor Yellow

$sensitiveFiles = @(
    "server/.env",
    "lib/firebase_options.dart",
    "android/app/google-services.json",
    "ios/Runner/GoogleService-Info.plist"
)

foreach ($file in $sensitiveFiles) {
    if (git ls-files | Select-String -Pattern "^$file$" -Quiet) {
        Write-Host " FOUND: $file in staging area!" -ForegroundColor Red
        $ISSUES++
    } else {
        Write-Host " $file not tracked" -ForegroundColor Green
    }
}

# Final verdict
Write-Host ""
if ($ISSUES -eq 0) {
    Write-Host " All checks passed! Safe to push to GitHub." -ForegroundColor Green
    Write-Host "   Run: git add . && git commit -m 'Your message' && git push" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "  Found $ISSUES potential security issue(s)." -ForegroundColor Yellow
    Write-Host "Please review the warnings above." -ForegroundColor Yellow
    Write-Host "If these are example/template files, you can proceed." -ForegroundColor Yellow
    Write-Host "If these contain real credentials, DO NOT PUSH!" -ForegroundColor Red
    exit 1
}
