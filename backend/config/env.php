<?php
// Copy this file to env.local.php and fill in real values. Never commit secrets.

define('DB_HOST', getenv('DB_HOST') ?: 'localhost');
define('DB_NAME', getenv('DB_NAME') ?: 'pnwhs_rmc');
define('DB_USER', getenv('DB_USER') ?: 'root');
define('DB_PASS', getenv('DB_PASS') ?: '');

define('JWT_SECRET',     getenv('JWT_SECRET')     ?: 'CHANGE_THIS_SECRET_KEY');
define('JWT_EXPIRY',     (int)(getenv('JWT_EXPIRY') ?: 86400));

define('FCM_SERVER_KEY', getenv('FCM_SERVER_KEY') ?: '');
define('SMS_API_KEY',    getenv('SMS_API_KEY')    ?: '');
define('SMS_SENDER_ID',  getenv('SMS_SENDER_ID')  ?: 'PNWHS');

define('PAYFAST_MERCHANT_ID',  getenv('PAYFAST_MERCHANT_ID')  ?: '');
define('PAYFAST_MERCHANT_KEY', getenv('PAYFAST_MERCHANT_KEY') ?: '');
define('KUICKPAY_API_KEY',     getenv('KUICKPAY_API_KEY')     ?: '');

define('APP_ENV',  getenv('APP_ENV')  ?: 'production');
define('APP_URL',  getenv('APP_URL')  ?: 'https://api.pnwhs-rmc.com');
define('FRONTEND_URL', getenv('FRONTEND_URL') ?: 'https://admin.pnwhs-rmc.com');

define('S3_BUCKET',     getenv('S3_BUCKET')     ?: '');
define('S3_REGION',     getenv('S3_REGION')     ?: 'ap-south-1');
define('S3_KEY',        getenv('S3_KEY')        ?: '');
define('S3_SECRET',     getenv('S3_SECRET')     ?: '');
