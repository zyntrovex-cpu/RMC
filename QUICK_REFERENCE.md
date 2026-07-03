# Quick Reference Card

## Before You Start

- [ ] XAMPP is running (MySQL + Apache)
- [ ] Database `rmc_db` exists (import schema.sql if first time)
- [ ] Phone USB Debugging enabled (Settings → Developer Options)
- [ ] Phone connected via USB cable
- [ ] You know your PC's IP (run `ipconfig` and find IPv4 Address)
- [ ] Updated `mobile/lib/services/api_service.dart` with YOUR IP

## Build Commands (Copy & Paste)

```powershell
# Open PowerShell as Administrator

# Kill old processes
taskkill /F /IM java.exe 2>nul
taskkill /F /IM javaw.exe 2>nul
timeout /t 3

# Clean Gradle cache globally
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:USERPROFILE\.android" -ErrorAction SilentlyContinue

# Clean project
cd C:\xampp\htdocs\RMC\RMC\mobile
Remove-Item -Recurse -Force ".\build" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".\.gradle" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".\.dart_tool" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".\android\build" -ErrorAction SilentlyContinue

# Build
flutter clean
flutter pub get
flutter run
```

## API Endpoints to Know

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/resident-auth?action=login` | POST | Mobile app login |
| `/resident?action=dashboard` | GET | Home screen data |
| `/resident?action=my-challans` | GET | Challan list |
| `/resident?action=my-visitor-passes` | GET | Visitor passes |
| `/auth?action=login` | POST | Admin portal login |

## Test Credentials (Create via Admin Portal)

- Admin: `admin` / `Admin@1234`
- Test resident: Create via Admin portal → Users

## Expected IP Addresses

```
Your PC IPv4:        192.168.1.5 (check with ipconfig)
XAMPP Backend:       http://localhost/RMC/RMC/backend/ (on PC)
XAMPP Backend (WiFi):http://192.168.1.5/RMC/RMC/backend/ (from phone)
Admin Portal:        http://localhost/RMC/RMC/admin/
XAMPP Dashboard:     http://localhost/dashboard/
```

## Troubleshooting Quick Fixes

| Issue | Fix |
|-------|-----|
| "Gradle workspace corruption" | Run the clean commands above; restart |
| "Device not found" | Check USB cable; enable USB Debugging; `adb devices` |
| "Connection refused" | Check phone Wi-Fi; verify IP with `ipconfig`; check firewall |
| "Database error" | XAMPP MySQL must be running; import schema.sql |
| "Login fails" | Create test user in admin portal; check credentials; verify API endpoint |
| "App crashes" | Check logcat: `flutter run -v` to see full error |

## Key Files

```
mobile/lib/services/api_service.dart    ← UPDATE IP HERE
mobile/lib/services/auth_service.dart   ← Session storage (FIXED ✓)
mobile/android/gradle.properties        ← Gradle config (FIXED ✓)
backend/config/env.php                  ← Database config
database/schema.sql                     ← Database structure
SETUP_GUIDE.md                          ← Full instructions
GRADLE_FIX_GUIDE.md                     ← Gradle troubleshooting
```

## Quick Diagnostic

```powershell
# Check Flutter setup
flutter doctor -v

# Check Android device
adb devices

# Check Java version (should be 11)
java -version

# Test backend API
$uri = "http://192.168.1.5/RMC/RMC/backend/resident-auth?action=check-plot"
$body = @{ sector_code="A"; plot_no="1" } | ConvertTo-Json
Invoke-WebRequest -Method POST -Uri $uri -ContentType "application/json" -Body $body
```

## Expected Build Time

- First build: 5-10 minutes (downloads Gradle, dependencies)
- Subsequent builds: 2-3 minutes
- APK size: ~80-100 MB

## Success Indicators

- ✅ `flutter run` completes without errors
- ✅ APK installs on Pixel 6
- ✅ App starts and shows splash screen
- ✅ Login page loads
- ✅ Can login with test credentials
- ✅ Dashboard loads with real data
- ✅ API calls complete successfully

## Panic Button

If everything is broken:

1. Close VS Code / IDE
2. Kill all Java: `taskkill /F /IM java.exe`
3. Delete caches:
   - `Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle"`
   - `cd C:\xampp\htdocs\RMC\RMC\mobile && Remove-Item -Recurse -Force .\build`
4. Start fresh: `flutter clean && flutter pub get && flutter run`

## Don't Forget

- The phone and PC must be on the **same Wi-Fi network**
- The IP address in `api_service.dart` must match your PC's actual Wi-Fi IPv4
- XAMPP must be running (MySQL + Apache)
- Database must be initialized
- USB Debugging must be enabled on phone

---

**Last Updated**: July 3, 2026
**Ready to Build**: YES ✅
**Time to Deploy**: ~30 minutes
