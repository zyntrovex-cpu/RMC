<?php
/**
 * Mobile App — Resident self-service endpoints
 * Dashboard, dues, challans, payments, profile, notifications
 */
require_once __DIR__ . '/../config/bootstrap.php';

class ResidentController {
    private PDO $db;
    private array $me;

    public function __construct() {
        $this->db = Database::get();
        $this->me = AuthMiddleware::require('owner', 'tenant');
    }

    public function dashboard(): void {
        $userId = $this->me['sub'];

        $propStmt = $this->db->prepare(
            "SELECT p.*, s.code as sector_code, s.name as sector_name, pc.label as category
             FROM properties p
             JOIN sectors s ON s.id = p.sector_id
             JOIN property_categories pc ON pc.id = p.category_id
             WHERE p.registered_user_id = ?"
        );
        $propStmt->execute([$userId]);
        $property = $propStmt->fetch();

        if (!$property) Response::error('No property linked to your account.', 404);

        $propertyId = $property['id'];
        $month      = date('Y-m');

        $challansStmt = $this->db->prepare(
            "SELECT c.*, a.name as account_name, a.code as account_code
             FROM challans c
             JOIN accounts a ON a.id = c.account_id
             WHERE c.property_id=? AND DATE_FORMAT(c.issue_date,'%Y-%m')=?
             ORDER BY a.sort_order"
        );
        $challansStmt->execute([$propertyId, $month]);
        $currentChallans = $challansStmt->fetchAll();

        $outStmt = $this->db->prepare(
            "SELECT COALESCE(SUM(total_amount),0) as total
             FROM challans WHERE property_id=? AND status IN ('unpaid','partial','overdue')"
        );
        $outStmt->execute([$propertyId]);
        $outstanding = (float) $outStmt->fetchColumn();

        $notifCount = $this->db->prepare(
            "SELECT COUNT(*) FROM notifications WHERE user_id=? AND is_read=0"
        );
        $notifCount->execute([$userId]);

        $recentPmt = $this->db->prepare(
            "SELECT py.*, c.challan_no, a.name as account_name
             FROM payments py
             JOIN challans c ON c.id = py.challan_id
             JOIN accounts a ON a.id = c.account_id
             WHERE py.property_id=?
             ORDER BY py.created_at DESC LIMIT 3"
        );
        $recentPmt->execute([$propertyId]);

        $announcements = $this->db->prepare(
            "SELECT id, title, body, is_pinned, created_at
             FROM announcements
             WHERE (sector_id IS NULL OR sector_id=?)
               AND (expires_at IS NULL OR expires_at >= CURDATE())
             ORDER BY is_pinned DESC, created_at DESC
             LIMIT 5"
        );
        $announcements->execute([$property['sector_id']]);

        Response::success([
            'property'             => $property,
            'current_challans'     => $currentChallans,
            'total_outstanding'    => $outstanding,
            'unread_notifications' => (int)$notifCount->fetchColumn(),
            'recent_payments'      => $recentPmt->fetchAll(),
            'announcements'        => $announcements->fetchAll(),
        ]);
    }

    public function myChallans(): void {
        $userId  = $this->me['sub'];
        $page    = max(1, (int)($_GET['page'] ?? 1));
        $perPage = 20;
        $offset  = ($page - 1) * $perPage;

        $propStmt = $this->db->prepare("SELECT id FROM properties WHERE registered_user_id=?");
        $propStmt->execute([$userId]);
        $prop = $propStmt->fetch();
        if (!$prop) Response::error('No property linked.', 404);

        $where = ['c.property_id = ?'];
        $params = [$prop['id']];
        if (!empty($_GET['status'])) { $where[] = 'c.status=?'; $params[] = $_GET['status']; }
        if (!empty($_GET['month']))  { $where[] = "DATE_FORMAT(c.issue_date,'%Y-%m')=?"; $params[] = $_GET['month']; }
        $whereStr = implode(' AND ', $where);

        $countStmt = $this->db->prepare("SELECT COUNT(*) FROM challans c WHERE $whereStr");
        $countStmt->execute($params);
        $total = (int)$countStmt->fetchColumn();

        $stmt = $this->db->prepare(
            "SELECT c.*, a.name as account_name, a.code as account_code
             FROM challans c
             JOIN accounts a ON a.id = c.account_id
             WHERE $whereStr
             ORDER BY c.issue_date DESC, a.sort_order
             LIMIT $perPage OFFSET $offset"
        );
        $stmt->execute($params);
        Response::paginated($stmt->fetchAll(), $total, $page, $perPage);
    }

    public function myPayments(): void {
        $userId = $this->me['sub'];
        $propStmt = $this->db->prepare("SELECT id FROM properties WHERE registered_user_id=?");
        $propStmt->execute([$userId]);
        $prop = $propStmt->fetch();
        if (!$prop) Response::error('No property linked.', 404);

        $stmt = $this->db->prepare(
            "SELECT py.*, c.challan_no, a.name as account_name
             FROM payments py
             JOIN challans c ON c.id = py.challan_id
             JOIN accounts a ON a.id = c.account_id
             WHERE py.property_id=?
             ORDER BY py.created_at DESC
             LIMIT 50"
        );
        $stmt->execute([$prop['id']]);
        Response::success($stmt->fetchAll());
    }

    public function myProfile(): void {
        $stmt = $this->db->prepare(
            "SELECT u.id, u.full_name, u.cnic, u.mobile, u.mobile_alt, u.whatsapp, u.email,
                    u.role, u.status, u.last_login,
                    p.plot_no, p.occupancy, p.blacklisted,
                    s.code as sector_code, s.name as sector_name,
                    pc.label as category
             FROM users u
             LEFT JOIN properties p ON p.registered_user_id = u.id
             LEFT JOIN sectors s ON s.id = p.sector_id
             LEFT JOIN property_categories pc ON pc.id = p.category_id
             WHERE u.id = ?"
        );
        $stmt->execute([$this->me['sub']]);
        Response::success($stmt->fetch());
    }

    public function updateProfile(): void {
        $v = Validator::fromRequest();
        $v->email('email');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $allowed = ['full_name','mobile_alt','whatsapp','email'];
        $set = []; $params = [];
        foreach ($allowed as $f) {
            if ($v->get($f) !== null) { $set[] = "$f=?"; $params[] = $v->get($f); }
        }
        if ($v->get('fcm_token')) { $set[] = 'fcm_token=?'; $params[] = $v->get('fcm_token'); }

        if (!empty($set)) {
            $params[] = $this->me['sub'];
            $this->db->prepare("UPDATE users SET " . implode(',', $set) . " WHERE id=?")->execute($params);
        }
        $this->myProfile();
    }

    public function notifications(): void {
        $stmt = $this->db->prepare(
            "SELECT * FROM notifications WHERE user_id=?
             ORDER BY created_at DESC LIMIT 50"
        );
        $stmt->execute([$this->me['sub']]);
        $notifications = $stmt->fetchAll();

        $this->db->prepare("UPDATE notifications SET is_read=1 WHERE user_id=?")->execute([$this->me['sub']]);
        Response::success($notifications);
    }

    public function announcements(): void {
        $propStmt = $this->db->prepare("SELECT sector_id FROM properties WHERE registered_user_id=?");
        $propStmt->execute([$this->me['sub']]);
        $prop = $propStmt->fetch();
        $sectorId = $prop['sector_id'] ?? null;

        $stmt = $this->db->prepare(
            "SELECT a.*, u.full_name as posted_by
             FROM announcements a
             JOIN users u ON u.id = a.created_by
             WHERE (a.sector_id IS NULL OR a.sector_id=?)
               AND (a.expires_at IS NULL OR a.expires_at >= CURDATE())
             ORDER BY a.is_pinned DESC, a.created_at DESC
             LIMIT 30"
        );
        $stmt->execute([$sectorId]);
        Response::success($stmt->fetchAll());
    }
}

$ctrl   = new ResidentController();
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

match (true) {
    $method === 'GET'  && $action === 'dashboard'      => $ctrl->dashboard(),
    $method === 'GET'  && $action === 'challans'        => $ctrl->myChallans(),
    $method === 'GET'  && $action === 'payments'        => $ctrl->myPayments(),
    $method === 'GET'  && $action === 'profile'         => $ctrl->myProfile(),
    $method === 'PUT'  && $action === 'profile'         => $ctrl->updateProfile(),
    $method === 'GET'  && $action === 'notifications'   => $ctrl->notifications(),
    $method === 'GET'  && $action === 'announcements'   => $ctrl->announcements(),
    default => Response::error('Endpoint not found.', 404),
};
