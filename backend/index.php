<?php
require_once __DIR__ . '/config/bootstrap.php';

$uri    = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
// Strip everything up to and including the script's directory so routing
// works regardless of whether the backend lives at /api, /RMC/RMC/backend, etc.
$base   = rtrim(dirname($_SERVER['SCRIPT_NAME']), '/');
$uri    = trim(substr($uri, strlen($base)), '/');
$parts  = explode('/', $uri);
$module = $parts[0] ?? '';

if (!empty($parts[1]) && is_numeric($parts[1])) {
    $_GET['id'] = $parts[1];
}
if (!empty($parts[2])) {
    $_GET['action'] = $parts[2];
}

match ($module) {
    'auth'          => require __DIR__ . '/controllers/AuthController.php',
    'resident-auth' => require __DIR__ . '/controllers/ResidentAuthController.php',
    'resident'      => require __DIR__ . '/controllers/ResidentController.php',
    'sectors'       => require __DIR__ . '/controllers/SectorController.php',
    'properties'    => require __DIR__ . '/controllers/PropertyController.php',
    'users'         => require __DIR__ . '/controllers/UserController.php',
    'accounts'      => require __DIR__ . '/controllers/AccountController.php',
    'challans'      => require __DIR__ . '/controllers/ChallanController.php',
    'payments'      => require __DIR__ . '/controllers/PaymentController.php',
    'reports'       => require __DIR__ . '/controllers/ReportController.php',
    'complaints'    => require __DIR__ . '/controllers/ComplaintController.php',
    'announcements' => require __DIR__ . '/controllers/AnnouncementController.php',
    'noc'           => require __DIR__ . '/controllers/NOCController.php',
    'visitors'      => require __DIR__ . '/controllers/VisitorController.php',
    default         => Response::error('API route not found.', 404),
};
