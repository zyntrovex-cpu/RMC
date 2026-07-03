# PNWHS RMC - Complete Setup & Build Guide

## Prerequisites Check

Before building, verify you have:

- **Flutter**: 3.44.4 (check with `flutter --version`)
- **Dart**: 3.x (comes with Flutter)
- **Java**: JDK 11 (set JAVA_HOME to JDK 11 location)
- **Android SDK**: API 34+ with platform tools
- **XAMPP**: Running with MySQL started
- **Database**: `rmc_db` created and schema initialized

## Step 1: Verify Environment

```powershell
# Check Flutter version
flutter --version

# Check Dart version
dart --version

# Check Java version (should show 11)
java -version

# Check Android SDK
flutter doctor -v

# Verify XAMPP is running
# MySQL should be running on localhost:3306
```

## Step 2: Initialize Database (First Time Only)

```powershell
# Copy the schema file to your XAMPP MySQL folder or import via phpMyAdmin

# Via phpMyAdmin:
# 1. Open http://localhost/phpmyadmin
# 2. Create new database: rmc_db
# 3. Import: database/schema.sql
# 4. Run: database/migrations/001_advanced_features.sql
```

## Step 3: Update Backend Configuration (If Needed)

Edit `backend/config/env.php` to match your XAMPP setup:

```php
define('DB_HOST', 'localhost');
define('DB_NAME', 'rmc_db');
define('DB_USER', 'root');
define('DB_PASS', ''); // Empty if no password set in XAMPP
```

## Step 4: Verify Admin Portal

```
Open: http://localhost/RMC/RMC/admin/
Should see login page
Default credentials: admin / Admin@1234
```

## Step 5: Configure Mobile App

### Get Your PC's IP Address

```powershell
ipconfig
```

Look for "IPv4 Address" under your active network (usually starts with 192.168.x.x or 10.x.x.x)

### Update Backend IP in Code

Edit `mobile/lib/services/api_service.dart`:

```dart
static const _pcIp = '192.168.1.5'; // Replace with YOUR PC's IP
```

**Important**: The mobile phone must be on the SAME Wi-Fi network as your PC!

## Step 6: Clean Previous Build

```powershell
cd mobile

# Kill all Gradle processes
taskkill /F /IM java.exe
taskkill /F /IM javaw.exe
taskkill /F /IM gradle.exe

# Wait a moment
Start-Sleep -Seconds 3

# Delete all Gradle and Flutter caches
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:USERPROFILE\.android" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".\build" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".\.gradle" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".\.dart_tool" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".\android\build" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".\android\.gradle" -ErrorAction SilentlyContinue

echo "Cleanup complete"
```

## Step 7: Prepare Flutter Project

```powershell
cd mobile

# Get dependencies
flutter clean
flutter pub get

# If there are any compilation issues with native packages:
# Run from the project root
flutter pub cache repair
```

## Step 8: Connect Android Device

```powershell
# Enable USB Debugging on your Pixel 6:
# 1. Settings → About phone
# 2. Tap Build number 7 times to enable Developer Options
# 3. Settings → Developer Options
# 4. Enable USB Debugging
# 5. Connect phone via USB cable

# Verify device is connected:
flutter devices

# You should see: Pixel 6 (mobile) • • android • Android 14+
```

## Step 9: Build APK

```powershell
# If you see device listed in flutter devices:
flutter run

# To build APK without running:
flutter build apk --debug

# The APK will be at:
# build/app/outputs/apk/debug/app-debug.apk
```

## Troubleshooting

### Issue: "Gradle workspace corruption" Error

This means the Gradle cache is corrupted. Run the clean script from Step 6 and retry.

### Issue: "JAVA_HOME not set" Error

```powershell
# Find your JDK 11 installation
dir "C:\Program Files\Java" | grep -i "jdk-11"

# Set JAVA_HOME (add to PowerShell profile)
$env:JAVA_HOME = "C:\Program Files\Java\jdk-11.0.x"

# Verify
echo $env:JAVA_HOME
```

### Issue: "Android SDK not found" Error

```powershell
# Update Flutter to find Android SDK
flutter config --android-sdk "C:\Users\<YourUsername>\AppData\Local\Android\Sdk"

# Run flutter doctor to verify
flutter doctor
```

### Issue: "Device not found" after connecting

```powershell
# Restart ADB daemon
flutter doctor --verbose

# If still not showing, try:
adb kill-server
adb start-server
adb devices

# Check USB cable and USB Debugging permission on device
```

### Issue: "Connection to 192.168.1.5 refused"

1. Verify PC's IP: run `ipconfig` on your Windows machine
2. Update `api_service.dart` with correct IP
3. Check XAMPP is running: http://localhost/dashboard
4. Phone must be on SAME Wi-Fi network
5. Check Windows Firewall isn't blocking port 80:
   - Settings → Firewall & network protection
   - Allow an app through firewall
   - Add Apache (or PHP executable)

### Issue: "Mobile app crashes on login"

1. Check backend is running: `http://your-pc-ip/RMC/RMC/backend/resident-auth?action=check-plot`
2. Database might not be initialized - see Step 2
3. Check browser console (F12) for API errors on admin portal first

### Issue: APK installs but won't run

1. Check if phone meets minimum requirements (Android 6+, 100MB free space)
2. Uninstall old version: `flutter uninstall`
3. Try again: `flutter run`

## Testing After Build

### 1. Test Admin Portal

```
1. Open http://localhost/RMC/RMC/admin/ in browser
2. Login with: admin / Admin@1234
3. Navigate to Users → Create new test user
4. Note the mobile number and password
```

### 2. Test Mobile App Login

```
1. App should show splash screen then login page
2. Enter test user's mobile and password
3. Click Login
4. Should navigate to Home screen showing dashboard
5. Check that data loads (challengan, visitor passes, etc.)
```

### 3. Test Backend API Directly

```powershell
# Test login endpoint
Invoke-WebRequest -Method POST `
  -Uri "http://192.168.1.5/RMC/RMC/backend/resident-auth?action=login" `
  -ContentType "application/json" `
  -Body '{"mobile":"0300123456","password":"test123"}'

# Should return JSON with token and user data
```

## Common API Endpoints

- `POST /resident-auth?action=login` - Mobile app login
- `POST /resident-auth?action=register` - Mobile app registration
- `GET /resident?action=dashboard` - Resident dashboard
- `GET /resident?action=my-challans` - Get challans for resident
- `POST /auth?action=login` - Admin portal login
- `GET /properties` - Get all properties (admin)

## Build Configuration Summary

```
Flutter Version:    3.44.4
Dart Version:       3.x
Gradle Version:     8.0.0
AGP Version:        8.0.0
Kotlin Version:     1.8.0
Java Version:       JDK 11
Min Android SDK:    23
Target Android SDK: 34

Backend:            PHP 8+ with PDO/MySQL
Database:           MySQL 5.7+ (in XAMPP)
Admin Portal:       Vanilla HTML/CSS/JS (no build)
Authentication:     JWT in Authorization header
```

## File Structure

```
RMC/
├── admin/                      (Admin portal - http://localhost/RMC/RMC/admin/)
├── backend/                    (PHP API - http://localhost/RMC/RMC/backend/)
├── mobile/                     (Flutter app - builds to APK)
│   ├── lib/
│   │   ├── main.dart          (App entry point)
│   │   ├── services/          (API and Auth services)
│   │   └── screens/           (UI screens)
│   ├── android/               (Android native code)
│   └── pubspec.yaml           (Dependencies)
└── database/
    ├── schema.sql             (Database structure)
    └── migrations/            (Schema updates)
```

## Important Notes

1. **Local Storage**: Session data stored in-memory only (lost when app closes) - for testing
2. **Plain HTTP**: App uses `usesCleartextTraffic=true` to allow HTTP - for local dev only
3. **JWT Token**: Sent in `Authorization: Bearer <token>` header
4. **Database**: Make sure MySQL is running in XAMPP before building
5. **Wi-Fi IP**: Phone and PC must be on same network; phone uses PC's Wi-Fi IP to connect

## Next Steps After Successful Build

1. **Install release signing** - For app store releases
2. **Add persistent storage** - Use flutter_secure_storage or shared_preferences
3. **Implement notifications** - FCM for push notifications
4. **Add payment integration** - Connect to PayFast/KuickPay
5. **Production deployment** - Deploy backend to actual server with HTTPS

---

For issues or questions, check the error messages carefully and refer to the Troubleshooting section above.
