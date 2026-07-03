<?php
require_once __DIR__ . '/../config/bootstrap.php';

class SettingsController {
    private PDO $db;

    public function __construct() {
        $this->db = Database::get();
        AuthMiddleware::require('super_admin', 'rmc_admin');
    }

    public function cronLog(): void {
        $stmt = $this->db->prepare(
            "SELECT * FROM cron_log ORDER BY started_at DESC LIMIT 20"
        );
        $stmt->execute();
        Response::success($stmt->fetchAll());
    }

    public function runCron(): void {
        $admin  = AuthMiddleware::user();
        $month  = date('Y-m');
        $result = ChallanHelper::generateMonthlyBatch($this->db, $month, $admin['sub']);
        Response::success($result, 'Cron executed manually.');
    }
}

$ctrl   = new SettingsController();
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

match (true) {
    $method === 'GET'  && $action === 'cron-log' => $ctrl->cronLog(),
    $method === 'POST' && $action === 'run-cron' => $ctrl->runCron(),
    default => Response::error('Not found.', 404),
};
