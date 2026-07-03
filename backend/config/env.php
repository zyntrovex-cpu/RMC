<?php
define('DB_HOST', getenv('DB_HOST') ?: 'localhost');
define('DB_NAME', getenv('DB_NAME') ?: 'rmc_db');
define('DB_USER', getenv('DB_USER') ?: 'root');
define('DB_PASS', getenv('DB_PASS') ?: '');

define('JWT_SECRET',     getenv('JWT_SECRET')     ?: 'pnwhs-rmc-secret-key-2024-change-in-production');
define('JWT_EXPIRY',     (int)(getenv('JWT_EXPIRY') ?: 86400));

define('FCM_SERVER_KEY', getenv('FCM_SERVER_KEY') ?: '');
define('SMS_API_KEY',    getenv('SMS_API_KEY')    ?: '');
define('SMS_SENDER_ID',  getenv('SMS_SENDER_ID')  ?: 'PNWHS');

define('PAYFAST_MERCHANT_ID',  getenv('PAYFAST_MERCHANT_ID')  ?: '');
define('PAYFAST_MERCHANT_KEY', getenv('PAYFAST_MERCHANT_KEY') ?: '');
define('KUICKPAY_API_KEY',     getenv('KUICKPAY_API_KEY')     ?: '');

define('APP_ENV',      getenv('APP_ENV')      ?: 'development');
define('APP_URL',      getenv('APP_URL')      ?: 'http://localhost');
define('FRONTEND_URL', getenv('FRONTEND_URL') ?: '*');

define('S3_BUCKET', getenv('S3_BUCKET') ?: '');
define('S3_REGION', getenv('S3_REGION') ?: 'ap-south-1');
define('S3_KEY',    getenv('S3_KEY')    ?: '');
define('S3_SECRET', getenv('S3_SECRET') ?: '');
