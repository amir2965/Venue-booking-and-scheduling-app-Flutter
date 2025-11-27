#!/bin/bash
# Pre-push Security Check Script

echo " Running security checks before GitHub push..."
echo ""

# Check for sensitive strings
echo "Checking for API keys and passwords..."
ISSUES=0

# Check for Firebase API key
if git grep -q "AIzaSyAt05j02Wh4711p8EZb4hc7RFz1i42rUzc" 2>/dev/null; then
    echo " FOUND: Firebase API key in tracked files!"
    ISSUES=
else
    echo " No Firebase API keys found"
fi

# Check for MongoDB password
if git grep -q "SKLpVgXjQLo1LbnP" 2>/dev/null; then
    echo " FOUND: MongoDB password in tracked files!"
    ISSUES=
else
    echo " No MongoDB passwords found"
fi

# Check for MongoDB username
if git grep -q "amirmahdi82sf" 2>/dev/null; then
    echo " FOUND: MongoDB username in tracked files!"
    ISSUES=
else
    echo " No MongoDB usernames found"
fi

# Check for sensitive files
echo ""
echo "Checking for sensitive files in staging area..."

if git ls-files | grep -q "^server/\.env$"; then
    echo " FOUND: server/.env in staging area!"
    ISSUES=
else
    echo " server/.env not tracked"
fi

if git ls-files | grep -q "^lib/firebase_options\.dart$"; then
    echo " FOUND: lib/firebase_options.dart in staging area!"
    ISSUES=
else
    echo " lib/firebase_options.dart not tracked"
fi

if git ls-files | grep -q "^android/app/google-services\.json$"; then
    echo " FOUND: android/app/google-services.json in staging area!"
    ISSUES=
else
    echo " android/app/google-services.json not tracked"
fi

# Final verdict
echo ""
if [  -eq 0 ]; then
    echo " All checks passed! Safe to push to GitHub."
    exit 0
else
    echo " Found  security issue(s). DO NOT PUSH!"
    echo "Please remove sensitive data before pushing."
    exit 1
fi
