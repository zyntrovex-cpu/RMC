# Gradle Cache Corruption Fix - Complete Guide

## Problem Summary

You're seeing this error:
```
The contents of the immutable workspace 'C:\Users\muzam\.gradle\caches\9.1.0\transforms\...' 
have been modified. These workspace directories are not supposed to be modified once they are 
created. The modification might have been caused by an external process, or could be the result 
of disk corruption.
```

This happens because:
1. Gradle 9.1.0 was previously downloaded and cached
2. The cache got corrupted (possibly from interrupted builds or moving project between drives)
3. Even though we now specify Gradle 8.0, Flutter or AGP is still trying to use the corrupted 9.1.0 cache

## Solution - Complete Gradle Reset

### Option 1: Nuclear Option (Guaranteed to Work)

Run this PowerShell script:

```powershell
# STEP 1: Kill all Java/Gradle processes
Write-Host "Killing all Java processes..."
Get-Process | Where-Object {$_.ProcessName -match "java|gradle|flutter|dart|adb"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# STEP 2: Delete ALL Gradle caches globally
Write-Host "Deleting Gradle cache..."
$gradleHome = "$env:USERPROFILE\.gradle"
if (Test-Path $gradleHome) {
    Remove-Item -Recurse -Force $gradleHome
    Write-Host "Deleted $gradleHome"
}

# STEP 3: Delete Android SDK cache
Write-Host "Deleting Android SDK build cache..."
$androidHome = "$env:USERPROFILE\.android"
if (Test-Path $androidHome) {
    Remove-Item -Recurse -Force $androidHome
    Write-Host "Deleted $androidHome"
}

# STEP 4: Clean project build artifacts
Write-Host "Cleaning project build artifacts..."
cd mobile
if (Test-Path "build") { Remove-Item -Recurse -Force "build" -ErrorAction SilentlyContinue }
if (Test-Path ".gradle") { Remove-Item -Recurse -Force ".gradle" -ErrorAction SilentlyContinue }
if (Test-Path ".dart_tool") { Remove-Item -Recurse -Force ".dart_tool" -ErrorAction SilentlyContinue }
if (Test-Path "android/build") { Remove-Item -Recurse -Force "android/build" -ErrorAction SilentlyContinue }
if (Test-Path "android/.gradle") { Remove-Item -Recurse -Force "android/.gradle" -ErrorAction SilentlyContinue }

Write-Host "Complete Gradle reset finished!"
Write-Host ""
Write-Host "Next, run these commands:"
Write-Host "  cd mobile"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter run"
```

Save this as `GRADLE_RESET.ps1` and run:
```powershell
powershell -ExecutionPolicy Bypass -File .\GRADLE_RESET.ps1
```

### Option 2: Manual Step-by-Step

If you prefer to do it manually:

```powershell
# 1. Stop all processes
taskkill /F /IM java.exe 2>$null
taskkill /F /IM javaw.exe 2>$null
taskkill /F /IM gradle.exe 2>$null
taskkill /F /IM flutter.exe 2>$null
timeout /t 3 /nobreak

# 2. Delete Gradle cache
cd /d %USERPROFILE%
rmdir /s /q .gradle
rmdir /s /q .android

# 3. Go to project
cd C:\xampp\htdocs\RMC\RMC\mobile
rmdir /s /q build
rmdir /s /q .gradle
rmdir /s /q .dart_tool
rmdir /s /q android\build
rmdir /s /q android\.gradle

# 4. Verify cleanup
echo Cleanup complete!
```

## After Cleanup - Build with Verbose Output

```powershell
cd mobile

# Run with verbose to see what Gradle version is being used
flutter run -v > build_log.txt 2>&1

# Look for "gradle" in the output:
Select-String -Path .\build_log.txt -Pattern "gradle|Gradle|distributionUrl"
```

**You should see**: `gradle-8.0-all.zip` in the output
**You should NOT see**: `gradle-9.1.0`

## Prevention - Lock Gradle Version

We've already configured this, but here's the explanation:

### File: `mobile/android/gradle.properties`

```
org.gradle.daemon=false              # Disables daemon that keeps stale references
org.gradle.caching=false             # Disables problematic incremental cache
org.gradle.parallel=true             # Allow parallel compilation (safe)
```

### File: `mobile/android/gradle/wrapper/gradle-wrapper.properties`

```
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
```

This locks the exact Gradle version to 8.0.0.

## If Problem Persists After Full Cleanup

The issue might be that Flutter itself is forcing a newer Gradle. Try this:

```powershell
# Check what Flutter expects
flutter --version
flutter upgrade

# Check if there's a global Gradle version set
java -version
gradle --version  # If installed globally

# Reset Flutter cache
flutter cache clean

# Try again
cd mobile
flutter pub get
flutter run
```

## Emergency: Download Gradle Manually

If the wrapper download fails, manually download:

1. Download: https://services.gradle.org/distributions/gradle-8.0-all.zip
2. Extract to: `%USERPROFILE%\.gradle\wrapper\dists\gradle-8.0-all\<random-hash>`
3. Run `flutter run`

The hash can be found in the error message when it tries to download.

## Verification

After running the fix, verify:

```powershell
# Should NOT exist
Test-Path "$env:USERPROFILE\.gradle\caches\9.1.0"  # Should be False

# Should exist (will be recreated fresh)
Test-Path "$env:USERPROFILE\.gradle\wrapper\dists"  # Should be True

# Check Gradle version in project
cat mobile/android/gradle/wrapper/gradle-wrapper.properties | Select-String "distributionUrl"
# Should show: gradle-8.0-all.zip
```

## Last Resort - Check Java Version

```powershell
# Must be Java 11
java -version

# If wrong version, set JAVA_HOME
$env:JAVA_HOME = "C:\Program Files\Java\jdk-11.0.x"

# Verify
java -version
```

## Understanding the Error

The "immutable workspace modified" error happens because:

1. Gradle creates immutable caches for build artifacts
2. These caches are meant to be never modified after creation
3. If Gradle detects a modification, it means:
   - Different Gradle version tried to use same cache
   - External process modified cache files
   - Disk/filesystem issue
   - Project was moved between drives while Gradle daemon was running

**Solution**: Always run the Gradle daemon cleanup before switching versions or moving projects.

## Going Forward

To avoid this in the future:

1. **Always use the wrapper**: Never run `gradle` directly, always use `gradlew`
2. **Stop daemon before moving project**: `gradle --stop`
3. **Keep caches clean**: Run the cleanup script monthly
4. **Use consistent paths**: Don't move projects between drives mid-build

---

If the problem still exists after following all steps above, provide these details:

```
1. Output of: flutter --version
2. Output of: java -version
3. Output of: dir $env:USERPROFILE\.gradle\caches
4. Full error message from build
5. Contents of: mobile/android/gradle/wrapper/gradle-wrapper.properties
```
