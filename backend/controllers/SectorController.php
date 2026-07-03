<?php
require_once __DIR__ . '/../config/bootstrap.php';

class SectorController {
    private PDO $db;
    public function __construct() { $this->db = Database::get(); }

    public function index(): void {
        $rows = $this->db->query(
            "SELECT s.*, COUNT(p.id) as total_properties
             FROM sectors s
             LEFT JOIN properties p ON p.sector_id = s.id
             GROUP BY s.id ORDER BY s.code"
        )->fetchAll();
        Response::success($rows);
    }

    public function show(int $id): void {
        $stmt = $this->db->prepare(
            "SELECT s.*,
                COUNT(p.id) as total_properties,
                SUM(CASE WHEN p.occupancy='owner_occupied' THEN 1 ELSE 0 END) as owner_occupied,
                SUM(CASE WHEN p.occupancy='rented' THEN 1 ELSE 0 END) as rented,
                SUM(CASE WHEN p.occupancy='vacant' THEN 1 ELSE 0 END) as vacant
             FROM sectors s LEFT JOIN properties p ON p.sector_id = s.id AND p.is_active=1
             WHERE s.id = ? GROUP BY s.id"
        );
        $stmt->execute([$id]);
        $sector = $stmt->fetch();
        if (!$sector) Response::error('Sector not found.', 404);
        Response::success($sector);
    }

    public function streets(int $sectorId): void {
        $stmt = $this->db->prepare(
            "SELECT st.*, COUNT(p.id) as total_plots
             FROM streets st LEFT JOIN properties p ON p.street_id = st.id
             WHERE st.sector_id = ?
             GROUP BY st.id ORDER BY CAST(st.street_no AS UNSIGNED), st.street_no"
        );
        $stmt->execute([$sectorId]);
        Response::success($stmt->fetchAll());
    }

    public function stats(): void {
        $rows = $this->db->query(
            "SELECT s.code, s.name,
                COUNT(p.id) as total,
                SUM(CASE WHEN c.status='paid' THEN 1 ELSE 0 END) as paid_this_month,
                SUM(CASE WHEN c.status IN ('unpaid','overdue') THEN 1 ELSE 0 END) as unpaid_this_month
             FROM sectors s
             LEFT JOIN properties p ON p.sector_id = s.id AND p.is_active=1 AND p.facility_type='none'
             LEFT JOIN challans c ON c.property_id = p.id
                AND DATE_FORMAT(c.issue_date,'%Y-%m') = DATE_FORMAT(NOW(),'%Y-%m')
             GROUP BY s.id ORDER BY s.code"
        )->fetchAll();
        Response::success($rows);
    }
}

$ctrl = new SectorController();
$method = $_SERVER['REQUEST_METHOD'];
$id = isset($_GET['id']) ? (int)$_GET['id'] : null;
$action = $_GET['action'] ?? '';
AuthMiddleware::require('super_admin','rmc_admin','data_entry');

match (true) {
    $method === 'GET' && $action === 'stats' => $ctrl->stats(),
    $method === 'GET' && $id && $action === 'streets' => $ctrl->streets($id),
    $method === 'GET' && $id => $ctrl->show($id),
    $method === 'GET' => $ctrl->index(),
    default => Response::error('Endpoint not found.', 404),
};
