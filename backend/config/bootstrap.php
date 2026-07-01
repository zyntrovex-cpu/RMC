<?php
require_once __DIR__ . '/env.php';
require_once __DIR__ . '/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Validator.php';
require_once __DIR__ . '/../utils/ChallanHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';

// Suppress PHP error output — all errors must return JSON, never HTML
ini_set('display_errors', '0');
error_reporting(E_ALL);

// Global exception handler — converts any uncaught exception to a JSON 500
set_exception_handler(function (Throwable $e) {
    if (!headers_sent()) {
        http_response_code(500);
        header('Content-Type: application/json');
    }
    $msg = APP_ENV === 'development'
        ? $e->getMessage()
        : 'An internal server error occurred.';
    echo json_encode(['success' => false, 'message' => $msg, 'errors' => null]);
    exit;
});

// Global error handler — converts fatal errors to exceptions
set_error_handler(function (int $errno, string $errstr) {
    throw new \ErrorException($errstr, 0, $errno);
}, E_ALL & ~E_NOTICE & ~E_DEPRECATED);

header('Content-Type: application/json');
$origin = FRONTEND_URL === '*' ? '*' : FRONTEND_URL;
header('Access-Control-Allow-Origin: ' . $origin);
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Authorization, Content-Type');
header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}
