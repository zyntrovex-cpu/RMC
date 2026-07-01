# PNWHS RMC — Complete Deployment & Workflow Guide

## Project Overview

A full-stack Digital Society Management System for PNWHS bin Qasim / RMC Office, Karachi.

| Layer | Technology |
|-------|------------|
| Backend API | PHP 8+, MySQL, PDO, pure-PHP JWT (HS256) |
| Admin Portal | Vanilla HTML/CSS/JS (no framework) |
| Mobile App | Flutter (Android), Provider, FlutterSecureStorage |

---

## Repository Structure

```
RMC/
├── database/
│   ├── schema.sql                    # All 17 tables + seed data
│   └── migrations/
│       └── 001_advanced_features.sql # OTP, complaints, NOC, visitor passes, cron log
├── backend/
│   ├── .htaccess                     # URL rewriting → index.php
│   ├── index.php                     # Router
│   ├── config/
│   │   ├── env.php                   # DB credentials, JWT secret, OTP settings
│   │   ├── database.php              # PDO singleton
│   │   └── bootstrap.php            # Loads config + middleware
│   ├── middleware/
│   │   └── AuthMiddleware.php        # JWT decode + role enforcement
│   ├── utils/
│   │   ├── Response.php              # JSON response helpers
│   │   ├── Validator.php             # Input validation
│   │   └── ChallanHelper.php         # Challan/receipt number generation + arrears
│   ├── controllers/
│   │   ├── AuthController.php        # Admin login, me, change-password
│   │   ├── ResidentAuthController.php # check-plot, send-OTP, register, login, forgot/reset password
│   │   ├── ResidentController.php    # Dashboard, challans, visitor passes, NOC, complaints (resident)
│   │   ├── SectorController.php      # Sectors + streets CRUD
│   │   ├── PropertyController.php    # Property CRUD
│   │   ├── AccountController.php     # Fee accounts CRUD + rate history
│   │   ├── UserController.php        # User management
│   │   ├── ChallanController.php     # Challan list, detail, generate batch
│   │   ├── PaymentController.php     # Record payment, ledger
│   │   ├── ReportController.php      # Monthly/sector/house/annual/defaulters/arrears
│   │   ├── ComplaintController.php   # Complaints CRUD + comments
│   │   ├── AnnouncementController.php# Announcements + sector targeting
│   │   ├── NOCController.php         # NOC request → approve/reject → NOC number
│   │   ├── VisitorController.php     # Visitor pass CRUD + gate verify
│   │   └── SettingsController.php    # Org/bank settings, cron log
│   └── cron/
│       └── monthly_challans.php      # Auto-generate challans + auto-blacklist
├── admin/                            # Admin portal (HTML pages)
│   ├── login.html
│   ├── index.html                    # Dashboard
│   ├── properties.html
│   ├── challans.html
│   ├── payments.html
│   ├── defaulters.html
│   ├── complaints.html
│   ├── announcements.html
│   ├── noc.html
│   ├── reports.html
│   ├── users.html
│   ├── accounts.html
│   ├── settings.html
│   └── assets/
│       ├── css/main.css
│       └── js/
│           ├── api.js
│           └── app.js
└── mobile/                           # Flutter Android app
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── services/
        │   ├── auth_service.dart
        │   └── api_service.dart
        └── screens/
            ├── splash_screen.dart
            ├── login_screen.dart
            ├── register_screen.dart
            ├── home_screen.dart
            ├── challans_screen.dart
            ├── complaints_screen.dart
            ├── visitor_screen.dart
            ├── noc_screen.dart
            └── profile_screen.dart
```

---

## 1. Database Setup

### Requirements
- MySQL 5.7+ or MariaDB 10.3+

### Steps

```bash
mysql -u root -p

CREATE DATABASE rmc_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'rmc_user'@'localhost' IDENTIFIED BY 'StrongPassword123!';
GRANT ALL PRIVILEGES ON rmc_db.* TO 'rmc_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;

# Import schema
mysql -u rmc_user -p rmc_db < database/schema.sql
mysql -u rmc_user -p rmc_db < database/migrations/001_advanced_features.sql
```

### What gets seeded automatically
- **Sectors**: 1A, 1B, 1C, 2, 3, 4 (with sample streets per sector)
- **Fee Accounts**: Maintenance (PKR 500), Water Supply (PKR 300), Security (PKR 200), Sanitation (PKR 150)
- **Default Admin**: `admin` / `Admin@1234` (super_admin role) — **change immediately after first login**

---

## 2. Backend Deployment

### Requirements
- PHP 8.0+ with extensions: `pdo`, `pdo_mysql`, `json`, `mbstring`, `openssl`
- Apache with `mod_rewrite` enabled (or Nginx with equivalent config)

### Apache

```bash
# Place backend/ files at /var/www/html/api  (or a subdomain)
cp -r backend/* /var/www/html/api/

# Enable mod_rewrite
a2enmod rewrite

# In your VirtualHost or .htaccess, ensure AllowOverride All
# The backend/.htaccess handles routing automatically
```

### Environment Configuration

Edit `backend/config/env.php`:

```php
define('DB_HOST', 'localhost');
define('DB_NAME', 'rmc_db');
define('DB_USER', 'rmc_user');
define('DB_PASS', 'StrongPassword123!');
define('JWT_SECRET', 'CHANGE_THIS_TO_A_LONG_RANDOM_STRING_64_CHARS');
define('JWT_EXPIRY', 86400);        // 24 hours (seconds)
define('OTP_EXPIRY_MINUTES', 10);
define('OTP_RATE_LIMIT', 3);        // max OTPs per 10 min
```

**Generate a strong JWT secret:**
```bash
php -r "echo bin2hex(random_bytes(32));"  # 64-char hex string
```

### Nginx (alternative)

```nginx
server {
    listen 80;
    server_name api.pnwhs-rmc.com;
    root /var/www/api;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

### Verify backend is working

```bash
curl https://api.pnwhs-rmc.com/api/auth?action=login \
  -X POST -H 'Content-Type: application/json' \
  -d '{"mobile":"admin","password":"Admin@1234"}'
# Should return: {"success":true,"data":{"token":"..."}}
```

---

## 3. Admin Portal Deployment

The admin portal is pure static HTML/CSS/JS — no build step required.

```bash
# Serve from the same server under a different path or subdomain
cp -r admin/* /var/www/html/admin/
# OR serve at https://admin.pnwhs-rmc.com
```

### API base URL

The admin portal reads `window.API_BASE` (set in some pages) and falls back to `/api` in `api.js`. If your API is on a different domain:

Edit `admin/assets/js/api.js`, line 1:
```js
const BASE = 'https://api.pnwhs-rmc.com/api';
```

### First login

1. Open `https://admin.pnwhs-rmc.com/login.html`
2. Username: `admin` | Password: `Admin@1234`
3. Go to **Settings → Change Admin Password** immediately

---

## 4. Cron Job Setup

The cron script auto-generates monthly challans and auto-blacklists properties with 3+ months of unpaid challans.

```bash
# Edit crontab
crontab -e

# Run on the 1st of every month at 00:05 AM
5 0 1 * * php /var/www/api/cron/monthly_challans.php >> /var/log/rmc_cron.log 2>&1
```

### Manual trigger
From the Admin Portal: **Settings → Run Challan Cron Now (manual)**

### What the cron does
1. Finds all active properties
2. For each active fee account applicable to the property type
3. Generates a challan for the current month (skips if already exists)
4. Rolls over any unpaid previous challan amounts as arrears
5. Numbers challans as `PNWHS-YYYY-MM-ACCOUNTCODE-XXXXX`
6. Checks for properties with 3+ consecutive unpaid challans → marks as `blacklisted`
7. Logs result to `cron_log` table (visible in Settings → Cron Job Status)

---

## 5. Mobile App (Flutter Android)

### Requirements
- Flutter SDK 3.16+ (`flutter --version`)
- Android SDK / Android Studio
- A physical device or emulator (API 21+)

### Setup

```bash
cd mobile
flutter pub get
```

### Configure API base URL

Edit `mobile/lib/services/api_service.dart`, line 9:
```dart
static const _base = 'https://api.pnwhs-rmc.com/api';
```

For local development:
```dart
static const _base = 'http://10.0.2.2:8000/api';  // Android emulator → localhost
```

### Build & Run

```bash
# Debug run on connected device
flutter run

# Build release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

### Android permissions (android/app/src/main/AndroidManifest.xml)

Required permissions are standard. Add if missing:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.VIBRATE" />
```

---

## 6. Key API Endpoints Reference

### Admin Auth
| Method | Endpoint | Action |
|--------|----------|--------|
| POST | `/api/auth?action=login` | Admin login |
| GET | `/api/auth?action=me` | Get current admin |
| POST | `/api/auth?action=change-password` | Change password |

### Resident Auth
| Method | Endpoint | Action |
|--------|----------|--------|
| POST | `/api/resident-auth?action=check-plot` | Verify plot exists + no existing user |
| POST | `/api/resident-auth?action=send-otp` | Send OTP to mobile |
| POST | `/api/resident-auth?action=register` | Complete registration |
| POST | `/api/resident-auth?action=login` | Resident login |
| POST | `/api/resident-auth?action=forgot-password` | Send reset OTP |
| POST | `/api/resident-auth?action=reset-password` | Reset with OTP |

### Properties
| Method | Endpoint | Action |
|--------|----------|--------|
| GET | `/api/properties` | List with filters |
| POST | `/api/properties` | Create property |
| PUT | `/api/properties/{id}` | Update property |

### Challans
| Method | Endpoint | Action |
|--------|----------|--------|
| GET | `/api/challans` | List challans (with filters) |
| POST | `/api/challans?action=generate-batch` | Manually generate batch |
| GET | `/api/challans?action=by-number&no=PNWHS-...` | Look up by challan number |

### Payments
| Method | Endpoint | Action |
|--------|----------|--------|
| POST | `/api/payments` | Record payment |
| GET | `/api/payments` | Payment ledger |

### Reports
| Method | Endpoint | Action |
|--------|----------|--------|
| GET | `/api/reports?type=monthly&month=2026-07` | Monthly collection |
| GET | `/api/reports?type=sector&month=2026-07` | Sector-wise |
| GET | `/api/reports?type=house&property_id=1` | House-wise history |
| GET | `/api/reports?type=annual&year=2026` | Annual summary |
| GET | `/api/reports?type=defaulters` | All defaulters |
| GET | `/api/reports?type=arrears` | Arrears by account |

### NOC
| Method | Endpoint | Action |
|--------|----------|--------|
| GET | `/api/noc` | List NOC requests |
| POST | `/api/noc/{id}?action=approve` | Approve → generates NOC number |
| POST | `/api/noc/{id}?action=reject` | Reject with remarks |

### Visitor Passes
| Method | Endpoint | Action |
|--------|----------|--------|
| GET | `/api/visitors?action=verify&code=ABC123` | Gate staff verify pass |

---

## 7. Business Rules Summary

### One User Per Property
- Enforced at both DB level (`UNIQUE` on `property_id` in users) and controller level
- `check-plot` endpoint rejects if property already has a registered user

### Challan Numbering
- Format: `PNWHS-YYYY-MM-ACCOUNTCODE-XXXXX`
- Example: `PNWHS-2026-07-MAINT-00001`

### Receipt Numbering
- Format: `RCP-YYYYMMDD-XXXXXX`
- Example: `RCP-20260701-000042`

### NOC Number
- Format: `NOC-YYYY-XXXXX`
- NOC is valid for 6 months from approval date
- System blocks NOC if any unpaid challans exist

### Visitor Pass Code
- 6-character alphanumeric (e.g., `A3F9K2`)
- Single-use; marked `used` after gate verification
- Can be cancelled by resident before use

### OTP Policy
- 6 digits, 10-minute expiry
- Rate-limited: max 3 OTPs per mobile per 10 minutes
- Stored in `otp_verifications` table, expired codes auto-ignored

### Auto-Blacklist
- Cron checks: properties with 3+ months of **consecutive** unpaid/overdue challans
- Property status set to `blacklisted`
- NOC blocked, further challans still generated

### Arrears Roll-over
- When a new challan is generated, if the previous month's challan for the same account is unpaid, the outstanding amount is copied as `arrears` on the new challan
- `net_amount = monthly_amount + arrears`

---

## 8. Roles & Permissions

| Role | Description | Permissions |
|------|-------------|-------------|
| `super_admin` | Full system access | Everything |
| `rmc_admin` | Day-to-day operations | All except user role management |
| `data_entry` | Data entry staff | Properties, challans, payments |
| `owner` | Property owner | Resident portal only |
| `tenant` | Tenant/resident | Resident portal only |

---

## 9. Default Credentials

| System | Username | Password |
|--------|----------|----------|
| Admin Portal | `admin` | `Admin@1234` |

**Change the default password immediately after first login.**

---

## 10. Security Checklist

- [ ] Change default admin password
- [ ] Set a strong 64-char `JWT_SECRET` in `env.php`
- [ ] Use HTTPS everywhere (Let's Encrypt is free)
- [ ] Set `DB_PASS` to a strong password
- [ ] Restrict `backend/config/env.php` permissions: `chmod 640 env.php`
- [ ] Disable directory listing in Apache/Nginx
- [ ] Set up automated MySQL backups (`mysqldump` daily)
- [ ] Configure PHP `display_errors = Off` in production
- [ ] Review and tighten CORS in `backend/index.php` to your actual domains

---

## 11. SMS / OTP Integration

The backend's `ResidentAuthController.php` has a placeholder for SMS delivery:

```php
// In sendOtp() method, replace the TODO comment with your SMS gateway:
// Example: Twilio, Jazz (Mobilink), Telenor Pakistan, etc.
$this->sendSms($mobile, "Your PNWHS RMC OTP is: $code");
```

For testing without SMS, query the `otp_verifications` table directly:
```sql
SELECT code FROM otp_verifications WHERE mobile = '03XXXXXXXXX' ORDER BY created_at DESC LIMIT 1;
```

---

## 12. Troubleshooting

| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| 404 on API calls | mod_rewrite not enabled | `a2enmod rewrite`, restart Apache |
| 500 on all requests | PHP error / wrong credentials | Check `/var/log/apache2/error.log` |
| JWT errors on login | Wrong JWT_SECRET | Ensure consistent `JWT_SECRET` in `env.php` |
| Challans not generating | Cron not set up | Run `php cron/monthly_challans.php` manually |
| Mobile can't connect | Wrong API base URL | Update `_base` in `api_service.dart` |
| OTP not received | SMS gateway not configured | Read OTP from DB directly (dev only) |
| `Duplicate entry` on registration | Property already registered | One user per property enforced |
