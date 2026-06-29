<?php
require_once __DIR__ . '/../config/bootstrap.php';

class ChallanController {
    private PDO $db;

    public function __construct() {
        $this->db = Database::get();
    }

    public function index(): void {
        $page    = max(1, (int)($_GET['page'] ?? 1));
        $perPage = min(100, (int)($_GET['per_page'] ?? 25));
        $offset  = ($page - 1) * $perPage;

        $where = ['1=1']; $params = [];

        if (!empty($_GET['status']))      { $where[] = 'c.status = ?';                               $params[] = $_GET['status']; }
        if (!empty($_GET['sector_id']))   { $where[] = 'p.sector_id = ?';                            $params[] = $_GET['sector_id']; }
        if (!empty($_GET['account_id']))  { $where[] = 'c.account_id = ?';                           $params[] = $_GET['account_id']; }
        if (!empty($_GET['month']))       { $where[] = "DATE_FORMAT(c.issue_date,'%Y-%m') = ?";      $params[] = $_GET['month']; }
        if (!empty($_GET['property_id'])) { $where[] = 'c.property_id = ?';                          $params[] = $_GET['property_id']; }
        if (!empty($_GET['search'])) {
            $where[] = '(c.challan_no LIKE ? OR p.plot_no LIKE ? OR u.full_name LIKE ?)';
            $s = '%' . $_GET['search'] . '%';
            $params = array_merge($params, [$s, $s, $s]);
        }
        if (!empty($_GET['challan_no'])) { $where[] = 'c.challan_no = ?'; $params[] = $_GET['challan_no']; }

        $whereStr = implode(' AND ', $where);

        $countStmt = $this->db->prepare(
            "SELECT COUNT(*) FROM challans c
             JOIN properties p ON p.id = c.property_id
             LEFT JOIN ownership_records ow ON ow.property_id=p.id AND ow.is_current=1
             LEFT JOIN owners o ON o.id = ow.owner_id
             LEFT JOIN users u ON u.id = o.user_id
             WHERE $whereStr"
        );
        $countStmt->execute($params);
        $total = (int)$countStmt->fetchColumn();

        $stmt = $this->db->prepare(
            "SELECT c.*, p.plot_no, s.code as sector_code, a.name as account_name, a.code as account_code,
                u.full_name as owner_name, u.mobile as owner_mobile
             FROM challans c
             JOIN properties p ON p.id = c.property_id
             JOIN sectors s ON s.id = p.sector_id
             JOIN accounts a ON a.id = c.account_id
             LEFT JOIN ownership_records ow ON ow.property_id=p.id AND ow.is_current=1
             LEFT JOIN owners o ON o.id = ow.owner_id
             LEFT JOIN users u ON u.id = o.user_id
             WHERE $whereStr
             ORDER BY c.created_at DESC
             LIMIT $perPage OFFSET $offset"
        );
        $stmt->execute($params);
        Response::paginated($stmt->fetchAll(), $total, $page, $perPage);
    }

    public function show(int $id): void {
        $stmt = $this->db->prepare(
            "SELECT c.*,
                p.plot_no, p.occupancy, p.is_corner, p.is_canal_facing,
                s.code as sector_code, s.name as sector_name,
                st.street_no,
                a.name as account_name, a.code as account_code,
                u.full_name as owner_name, u.mobile as owner_mobile, u.cnic as owner_cnic
             FROM challans c
             JOIN properties p ON p.id = c.property_id
             JOIN sectors s ON s.id = p.sector_id
             LEFT JOIN streets st ON st.id = p.street_id
             JOIN accounts a ON a.id = c.account_id
             LEFT JOIN ownership_records ow ON ow.property_id=p.id AND ow.is_current=1
             LEFT JOIN owners o ON o.id = ow.owner_id
             LEFT JOIN users u ON u.id = o.user_id
             WHERE c.id = ?"
        );
        $stmt->execute([$id]);
        $challan = $stmt->fetch();
        if (!$challan) Response::error('Challan not found.', 404);

        $pmtStmt = $this->db->prepare(
            "SELECT py.*, u.full_name as recorded_by_name
             FROM payments py
             LEFT JOIN users u ON u.id = py.recorded_by
             WHERE py.challan_id = ?
             ORDER BY py.created_at DESC"
        );
        $pmtStmt->execute([$id]);
        $challan['payments'] = $pmtStmt->fetchAll();

        Response::success($challan);
    }

    public function generateBatch(): void {
        AuthMiddleware::require('super_admin', 'rmc_admin');
        $v = Validator::fromRequest();
        $v->required('month');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $admin  = AuthMiddleware::user();
        $result = ChallanHelper::generateMonthlyBatch($this->db, $v->get('month'), $admin['sub']);
        Response::success($result, "Batch generated: {$result['created']} challans created.");
    }

    public function cancel(int $id): void {
        AuthMiddleware::require('super_admin', 'rmc_admin');
        $v = Validator::fromRequest();
        $v->required('reason');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $admin = AuthMiddleware::user();
        $this->db->prepare(
            "UPDATE challans SET status='cancelled', cancelled_by=?, cancel_reason=? WHERE id=?"
        )->execute([$admin['sub'], $v->get('reason'), $id]);

        $this->db->prepare(
            "INSERT INTO audit_log (user_id, action, entity_type, entity_id, new_value)
             VALUES (?, 'challan.cancel', 'challan', ?, ?)"
        )->execute([$admin['sub'], $id, json_encode(['reason' => $v->get('reason')])]);

        Response::success(null, 'Challan cancelled.');
    }

    public function dashboard(): void {
        $month = $_GET['month'] ?? date('Y-m');

        $stats = $this->db->prepare(
            "SELECT
                COUNT(*) as total,
                SUM(CASE WHEN status='paid' THEN 1 ELSE 0 END) as paid,
                SUM(CASE WHEN status IN ('unpaid','overdue') THEN 1 ELSE 0 END) as unpaid,
                SUM(CASE WHEN status='partial' THEN 1 ELSE 0 END) as partial,
                SUM(total_amount) as total_billed,
                SUM(CASE WHEN status='paid' THEN total_amount ELSE 0 END) as total_collected
             FROM challans
             WHERE DATE_FORMAT(issue_date,'%Y-%m') = ?"
        );
        $stats->execute([$month]);
        $summary = $stats->fetch();

        $acctStmt = $this->db->prepare(
            "SELECT a.name, a.code,
                COUNT(c.id) as total,
                SUM(CASE WHEN c.status='paid' THEN 1 ELSE 0 END) as paid,
                SUM(c.total_amount) as billed,
                SUM(CASE WHEN c.status='paid' THEN c.total_amount ELSE 0 END) as collected
             FROM challans c
             JOIN accounts a ON a.id = c.account_id
             WHERE DATE_FORMAT(c.issue_date,'%Y-%m') = ?
             GROUP BY c.account_id
             ORDER BY a.sort_order"
        );
        $acctStmt->execute([$month]);
        $summary['by_account'] = $acctStmt->fetchAll();

        $sectStmt = $this->db->prepare(
            "SELECT s.code, s.name,
                COUNT(c.id) as total,
                SUM(CASE WHEN c.status='paid' THEN 1 ELSE 0 END) as paid,
                SUM(CASE WHEN c.status IN ('unpaid','overdue') THEN 1 ELSE 0 END) as unpaid
             FROM challans c
             JOIN properties p ON p.id = c.property_id
             JOIN sectors s ON s.id = p.sector_id
             WHERE DATE_FORMAT(c.issue_date,'%Y-%m') = ?
             GROUP BY s.id
             ORDER BY s.code"
        );
        $sectStmt->execute([$month]);
        $summary['by_sector'] = $sectStmt->fetchAll();

        Response::success($summary);
    }

    public function defaulters(): void {
        $stmt = $this->db->prepare(
            "SELECT p.plot_no, s.code as sector,
                u.full_name as owner_name, u.mobile,
                COUNT(DISTINCT c.id) as unpaid_challans,
                SUM(c.total_amount) as total_outstanding,
                MIN(c.due_date) as oldest_due_date,
                p.blacklisted
             FROM challans c
             JOIN properties p ON p.id = c.property_id
             JOIN sectors s ON s.id = p.sector_id
             LEFT JOIN ownership_records ow ON ow.property_id=p.id AND ow.is_current=1
             LEFT JOIN owners o ON o.id = ow.owner_id
             LEFT JOIN users u ON u.id = o.user_id
             WHERE c.status IN ('unpaid','overdue','partial')
             GROUP BY c.property_id
             ORDER BY total_outstanding DESC"
        );
        $stmt->execute();
        Response::success($stmt->fetchAll());
    }
}

$ctrl   = new ChallanController();
$method = $_SERVER['REQUEST_METHOD'];
$id     = isset($_GET['id']) ? (int)$_GET['id'] : null;
$action = $_GET['action'] ?? '';

AuthMiddleware::require('super_admin', 'rmc_admin', 'data_entry');

match (true) {
    $method === 'GET'  && $action === 'dashboard'          => $ctrl->dashboard(),
    $method === 'GET'  && $action === 'defaulters'         => $ctrl->defaulters(),
    $method === 'GET'  && $action === 'by-number'          => $ctrl->index(),
    $method === 'POST' && $action === 'generate-batch'     => $ctrl->generateBatch(),
    $method === 'POST' && $id && $action === 'cancel'      => $ctrl->cancel($id),
    $method === 'GET'  && $id                              => $ctrl->show($id),
    $method === 'GET'                                      => $ctrl->index(),
    default => Response::error('Endpoint not found.', 404),
};
