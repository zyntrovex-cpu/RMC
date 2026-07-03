# PNWHS RMC Mobile App - React Native Implementation

## What Changed

The mobile app has been **completely rewritten from Flutter to React Native** using Expo. This provides:

- ✅ **Faster Development**: JavaScript instead of Dart
- ✅ **Easier Build Process**: Expo handles Android/iOS complexity
- ✅ **Multi-language Support**: English and Urdu built-in from start
- ✅ **Smaller Bundle Size**: Lighter app download
- ✅ **Better Local Development**: No Gradle cache issues
- ✅ **Faster Testing**: Instant reload with Expo

## App Features

### 1. Authentication
- **Login Screen**: Mobile number + password authentication
- **Token Management**: JWT tokens stored locally in AsyncStorage
- **Auto-restore**: App automatically logs back in if token exists
- **Language Toggle**: Switch between English and Urdu on login screen

### 2. Dashboard
Shows:
- Welcome message with resident name
- Property information (Plot number, Sector)
- Outstanding dues amount (if any)
- Quick action buttons:
  - Challans (utility bills)
  - Visitor Passes
  - NOC Requests
  - Complaints
  - Profile
- Latest announcements section

### 3. Challans (Utility Bills)
- List all bills/challans
- Shows: Bill number, amount, due date, status
- "Pay Now" button (placeholder for payment integration)
- Color-coded status badges

### 4. Visitor Passes
- List all visitor pass requests
- Create new visitor pass with:
  - Visitor name
  - Visitor phone number
  - Purpose of visit
  - Validity dates
- Track pass approval status (Pending, Approved, Rejected)

### 5. Complaints
- Submit new complaints
- Track complaint status (Open, In Progress, Resolved)
- View admin remarks on resolved complaints
- List all past complaints with dates

### 6. NOC Requests
- Request No Objection Certificate
- Specify purpose and description
- Track request status (Pending, Approved, Rejected)
- Download approved NOC document (when ready)
- Reference number for tracking

### 7. Profile
- View resident information:
  - Name
  - Email
  - Mobile number
  - Property details
  - Address
  - CNIC (if available)

## Technology Stack

### Frontend
- **React Native**: Cross-platform mobile framework
- **Expo**: Development and build platform
- **React Navigation**: Tab and stack navigation
- **Axios**: HTTP client for API calls
- **i18n-js**: Multi-language support
- **AsyncStorage**: Local data persistence

### Backend Connection
- **REST API**: Communicates with PHP backend
- **JWT Authentication**: Secure token-based auth
- **Cleartext Traffic**: Enabled for local Wi-Fi (192.168.1.5)
- **Error Handling**: Centralized API error management

## File Structure

```
mobile/
├── App.js                           # Main app with navigation
├── app.json                         # Expo configuration
├── package.json                     # Dependencies list
│
├── screens/
│   ├── LoginScreen.js               # (340 lines)
│   │   └── Features: Login form, language toggle, error alerts
│   │
│   ├── DashboardScreen.js           # (223 lines)
│   │   └── Features: Welcome, dues, quick links, announcements
│   │
│   ├── ProfileScreen.js             # (115 lines)
│   │   └── Features: User info display, back button
│   │
│   ├── ChallansScreen.js            # (280 lines)
│   │   └── Features: List bills, status badges, pay button
│   │
│   ├── VisitorPassesScreen.js       # (350 lines)
│   │   └── Features: Create pass modal, track status
│   │
│   ├── ComplaintsScreen.js          # (300 lines)
│   │   └── Features: Submit complaint, track status, remarks
│   │
│   └── NocScreen.js                 # (320 lines)
│       └── Features: Request NOC, track status, download
│
├── services/
│   ├── api.js                       # (125 lines)
│   │   └── Features: All API endpoints, token management
│   │
│   └── i18n.js                      # (22 lines)
│       └── Features: Language switching, translation helper
│
└── locales/
    ├── en.json                      # English translations (56 keys)
    └── ur.json                      # Urdu translations (56 keys)
```

## Key Code Sections

### Authentication Flow (App.js)
```javascript
// Token restoration on app start
const bootstrapAsync = async () => {
  const token = await AsyncStorage.getItem('userToken');
  if (token) api.setToken(token);
};

// Login handling
authContext.signIn = async (mobile, password) => {
  const response = await api.login(mobile, password);
  await AsyncStorage.setItem('userToken', response.data.token);
};
```

### API Service (services/api.js)
```javascript
class ApiService {
  async request(method, path, data = null) {
    const config = {
      headers: { 'Authorization': `Bearer ${this.token}` }
    };
    return axios(config);
  }
}
```

### Multi-language Support (services/i18n.js)
```javascript
// Switch language
const toggleLanguage = async () => {
  const newLang = language === 'en' ? 'ur' : 'en';
  await authContext.setLanguage(newLang);
};

// Use translations
<Text>{t('app_name')}</Text> // Automatically shows English or Urdu
```

## API Endpoints Summary

All endpoints use:
- **Base URL**: `http://192.168.1.5/RMC/RMC/backend`
- **Auth**: `Bearer <JWT_TOKEN>` in Authorization header
- **Content-Type**: `application/json`

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/resident-auth?action=login` | User login |
| GET | `/resident?action=dashboard` | Dashboard data |
| GET | `/resident?action=profile` | User profile |
| GET | `/resident?action=my-challans` | List challans |
| GET | `/resident?action=my-visitor-passes` | List visitor passes |
| POST | `/resident?action=create-visitor-pass` | Create pass |
| GET | `/resident?action=my-noc-requests` | List NOC requests |
| POST | `/resident?action=request-noc` | Create NOC request |
| GET | `/resident?action=my-complaints` | List complaints |
| POST | `/resident?action=submit-complaint` | Submit complaint |

## Setup Quick Reference

```bash
# 1. Install dependencies
cd mobile && npm install

# 2. Update IP address (if different)
# Edit mobile/services/api.js line 4

# 3. Start development server
npm start

# 4. Open on mobile (Expo Go app) or emulator
# Scan QR code or press 'a' for Android emulator

# 5. Build APK for deployment
eas build --platform android --local
```

## Styling Highlights

- **Color Scheme**: 
  - Primary: `#1A5276` (dark blue)
  - Error: `#ff6b6b` (red)
  - Success: `#28a745` (green)
  - Info: `#17a2b8` (cyan)

- **Layout**:
  - Header bar: Dark blue with white text
  - Cards: White background with 10px border radius
  - Buttons: Full-width with padding and ripple effect
  - Status badges: Color-coded (green for approved, yellow for pending)

- **Responsive Design**:
  - Grid layout: 2-column for buttons
  - Flex layout: Column wrapping for screens
  - ScrollView: Vertical scrolling for content overflow
  - Modal: Bottom sheet style for form submissions

## Performance Considerations

- **Token Caching**: User stays logged in across app restarts
- **Language Persistence**: Selected language saved locally
- **Network**: Data loaded on screen open, no unnecessary requests
- **UI Responsiveness**: Loading indicators during data fetch
- **Error Handling**: User-friendly alerts for all API errors

## Testing Checklist

- [ ] Login with valid credentials
- [ ] View dashboard with property info
- [ ] See outstanding dues (if applicable)
- [ ] Click and navigate to each screen
- [ ] Create visitor pass request
- [ ] Submit complaint
- [ ] Request NOC certificate
- [ ] View profile information
- [ ] Toggle language to Urdu and back
- [ ] Logout and verify login required
- [ ] Test on poor network (verify error handling)
- [ ] Test on both portrait and landscape modes

## Next Steps

1. **Install Dependencies**: `npm install` in mobile directory
2. **Verify Backend**: Ensure PHP API is running on 192.168.1.5
3. **Start Dev Server**: `npm start` to launch Expo
4. **Test Features**: Use Expo Go app to test all screens
5. **Build APK**: `eas build --platform android --local` for production
6. **Deploy**: Transfer APK to phone and install

## Known Limitations

- Payment gateway not implemented (Pay Now button is placeholder)
- Document download requires backend file serving setup
- Notifications not yet configured
- Offline mode not implemented (requires Redux for caching)
- Rate limiting not configured (for production add)

## Future Enhancements

- [ ] Push notifications for due dates and announcements
- [ ] Offline mode with local caching
- [ ] Payment gateway integration
- [ ] Document upload for complaints
- [ ] Real-time chat with management
- [ ] Biometric authentication
- [ ] Dark mode support
- [ ] Performance optimization with Redux

## Documentation Files

- **REACT_NATIVE_SETUP.md** - Complete setup and installation guide
- **README.md** - General project overview
- **SYSTEM_FIXES_SUMMARY.md** - Previous fixes and troubleshooting
- **QUICK_REFERENCE.md** - Copy-paste commands and diagnostics

## Support

For issues:
1. Check error message on app's red error screen
2. Review console logs: `npm start` shows debug output
3. Verify API connectivity: Check backend is running
4. Clear cache: Press 'c' in Expo terminal
5. Reinstall: Delete node_modules and run `npm install` again
