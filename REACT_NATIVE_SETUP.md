# React Native Mobile App Setup Guide

## Overview

The PNWHS RMC mobile app is built with React Native using Expo, providing a cross-platform mobile experience for both Android and iOS. The app includes:

- **Authentication**: Mobile number + password login with JWT token storage
- **Multi-language Support**: English and Urdu with language toggle
- **Dashboard**: Overview of property, outstanding dues, and quick links
- **Features**: Challans, Visitor Passes, NOC requests, Complaints, and Profile management
- **Offline Support**: LocalStorage for token and language persistence
- **Responsive Design**: Consistent UI across all screen sizes

## Prerequisites

### Development Environment

- **Node.js**: Version 16+ (with npm 8+)
  - Download from: https://nodejs.org/

- **Expo CLI** (optional but recommended):
  ```bash
  npm install -g expo-cli
  ```

### Mobile Device

- **Android**: Pixel 6 or any Android 7+ device with USB debugging enabled
- **iOS**: iPhone 10+ with TestFlight app
- **Expo Go App**: Download from Google Play Store or App Store (for development testing)

### Network

- **PC Wi-Fi IP**: 192.168.1.5 (update in `mobile/services/api.js` if different)
- **Backend**: Running XAMPP with PHP API at `http://192.168.1.5/RMC/RMC/backend`

## Installation Steps

### Step 1: Install Dependencies

```bash
cd mobile
npm install
```

This installs all required packages:
- `expo`: Framework for building React Native apps
- `axios`: HTTP client for API calls
- `react-navigation`: Navigation library
- `@react-native-async-storage/async-storage`: Local data persistence
- `i18n-js`: Internationalization library
- And other dependencies

### Step 2: Update Backend IP (if different)

If your PC Wi-Fi IP is NOT 192.168.1.5:

1. Open `mobile/services/api.js`
2. Find: `const API_BASE = 'http://192.168.1.5/RMC/RMC/backend';`
3. Replace `192.168.1.5` with your actual IP address
4. Save the file

To find your IP on Windows:
```bash
ipconfig
```
Look for "IPv4 Address" under your Wi-Fi adapter.

On Mac/Linux:
```bash
ifconfig | grep inet
```

### Step 3: Start the Development Server

```bash
npm start
```

Or with Expo CLI:
```bash
expo start
```

This starts the Expo development server and shows a QR code in the terminal.

## Running on Android Device

### Option A: Using Expo Go (Fastest)

1. Install **Expo Go** app from Google Play Store on your Pixel 6
2. In the terminal, press `a` to open Android emulator or `w` for web
3. Or scan the QR code with your phone camera
4. App will launch in Expo Go

### Option B: Building APK for Direct Installation

```bash
eas build --platform android --local
```

Or with Expo CLI:
```bash
expo build:android -t apk
```

Once complete, download and install the APK:
```bash
adb install app-filename.apk
```

**Note**: The local build requires Java SDK and Android SDK set up. If you encounter issues, use Expo Go option.

## Testing the App

### Login Credentials

Use admin portal credentials:
- **Mobile**: As registered in backend database
- **Password**: Corresponding password

### Test Flow

1. **Launch App**: Login with valid credentials
2. **Dashboard**: View property info and outstanding dues
3. **Challans**: View all utility bills/challans
4. **Visitor Passes**: Create new visitor pass request
5. **Complaints**: Submit complaint to management
6. **NOC Requests**: Request No Objection Certificate
7. **Profile**: View user profile information
8. **Language**: Toggle between English and Urdu using button on login screen

### Common Issues & Fixes

#### "Cannot connect to server"
- Verify PC Wi-Fi IP in `mobile/services/api.js`
- Ensure backend PHP server is running on XAMPP
- Check firewall allows connections to port 80
- Verify device is on same Wi-Fi network as PC

#### "Login fails with error"
- Check credentials in admin portal database
- Verify backend database connection in `backend/config/env.php`
- Check PHP error logs in XAMPP

#### "App crashes on screen load"
- Check console logs: Run with `npm start` and look for red error screen
- Verify API endpoints in `mobile/services/api.js` match backend routes
- Check backend response format

#### "Language toggle doesn't work"
- Clear Expo app cache: Press `c` in terminal
- Restart development server

#### "AsyncStorage errors"
- Device storage full - free up space
- Reinstall Expo Go app
- Clear app data from phone settings

## Project Structure

```
mobile/
├── App.js                    # Main navigation and auth context
├── app.json                  # Expo configuration
├── package.json              # Dependencies
├── screens/
│   ├── LoginScreen.js        # Login with language toggle
│   ├── DashboardScreen.js    # Home screen with quick links
│   ├── ProfileScreen.js      # User profile view
│   ├── ChallansScreen.js     # Bills/utilities listing
│   ├── VisitorPassesScreen.js # Visitor management
│   ├── ComplaintsScreen.js   # Complaint submission
│   └── NocScreen.js          # NOC requests
├── services/
│   ├── api.js               # API service with all endpoints
│   └── i18n.js              # Language/translation service
└── locales/
    ├── en.json              # English translations
    └── ur.json              # Urdu translations
```

## API Endpoints Used

All endpoints require JWT token in Authorization header:

```
GET  /resident?action=dashboard        # Dashboard data
GET  /resident?action=profile          # User profile
GET  /resident?action=my-challans      # List challans
GET  /resident?action=my-visitor-passes # List visitor passes
POST /resident?action=create-visitor-pass # Create pass
GET  /resident?action=my-noc-requests  # List NOC requests
POST /resident?action=request-noc      # Create NOC request
GET  /resident?action=my-complaints    # List complaints
POST /resident?action=submit-complaint # Submit complaint
POST /resident-auth?action=login       # User login
```

## Building for Production

### Android APK

```bash
eas build --platform android
```

### iOS App

```bash
eas build --platform ios
```

### Using Expo build cloud:

```bash
expo build:android -t app-bundle  # For Google Play Store
expo build:ios                     # For App Store
```

## Troubleshooting

### Dependency Issues

```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
npm start -- --clear
```

### Port Already in Use

```bash
# Kill process using port 19000
# On Windows:
netstat -ano | findstr :19000
taskkill /PID <PID> /F

# On Mac/Linux:
lsof -i :19000
kill -9 <PID>
```

### Expo Connection Issues

```bash
# Try tunnel mode (slower but works over any internet)
expo start --tunnel

# Or LAN mode
expo start --lan
```

## Environment Configuration

The app auto-connects to backend at configured IP. Key configuration files:

- `mobile/services/api.js` - API base URL and token management
- `mobile/app.json` - Expo project settings, cleartext traffic enabled
- `mobile/screens/LoginScreen.js` - Language selection
- `mobile/locales/` - Translation strings

## Performance Optimization

- AsyncStorage caches authentication token locally
- Dashboard data is fetched on screen load
- Navigation uses Stack Navigator for smooth transitions
- Images optimized with React Native native scaling

## Security Notes

- JWT tokens stored in AsyncStorage (suitable for mobile)
- Authorization headers sent with all API requests
- Cleartext traffic allowed on local network (modify in `app.json` for production)
- No sensitive data logged to console

## Support

For backend API issues, check:
- `backend/config/database.php` - Database connection
- `backend/controllers/ResidentController.php` - Endpoint implementations
- `backend/config/bootstrap.php` - Error handling and CORS

For frontend issues, check:
- Browser console in Expo
- Mobile app error screen (red screen)
- Network inspector in DevTools

## Next Steps

1. Run `npm install` to install dependencies
2. Update IP address if needed
3. Run `npm start` to launch development server
4. Install Expo Go and scan QR code
5. Test login and app features
6. Build APK when ready for distribution
