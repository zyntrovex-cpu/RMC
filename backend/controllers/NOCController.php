<?php
require_once __DIR__ . '/../config/bootstrap.php';

class NOCController {
    private PDO $db;

    public function __construct() {
        $this->db = Database::get();
    }

    public function request(): void {
        $me = AuthMiddleware::require('owner');
        $v  = Validator::fromRequest();
        $v->required('purpose');
        $v->inList('purpose', ['sale','bank','general','transfer']);
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $ownerStmt = $this->db->prepare("SELECT id FROM owners WHERE user_id=?");
        $ownerStmt->execute([$me['sub']]);
        $owner = $ownerStmt->fetch();
        if (!$owner) Response::error('Owner record not found.', 404);

        $propStmt = $this->db->prepare("SELECT id FROM properties WHERE registered_user_id=?");
        $propStmt->execute([$me['sub']]);
        $prop = $propStmt->fetch();
        if (!$prop) Response::error('No property linked.', 404);

        $duesStmt = $this->db->prepare(
            "SELECT COUNT(*) FROM challans
             WHERE property_id=? AND status IN ('unpaid','overdue','partial')"
        );
        $duesStmt->execute([$prop['id']]);
        if ((int)$duesStmt->fetchColumn() > 0) {
            Response::error('NOC cannot be issued while there are outstanding dues. Please clear all dues first.', 400);
        }

        $pending = $this->db->prepare(
            "SELECT id FROM noc_requests WHERE property_id=? AND status='pending'"
        );
        $pending->execute([$prop['id']]);
        if ($pending->fetchColumn()) {
            Response::error('A NOC request is already pending for this property.', 409);
        }

        $this->db->prepare(
            "INSERT INTO noc_requests (property_id, owner_id, purpose) VALUES (?,?,?)"
        )->execute([$prop['id'], $owner['id'], $v->get('purpose')]);

        $admins = $this->db->query("SELECT id FROM users WHERE role IN ('super_admin','rmc_admin') AND status='active'")->fetchAll();
        foreach ($admins as $a) {
            $this->db->prepare(
                "INSERT INTO notifications (user_id, title, body, type)
                 VALUES (?, 'New NOC Request', 'A resident has requested a NOC. Please review.', 'system')"
            )->execute([$a['id']]);
        }

        Response::success(null, 'NOC request submitted. You will be notified once approved.', 201);
    }

    public function index(): void {
        $me = AuthMiddleware::require('super_admin','rmc_admin','owner');

        if (in_array($me['role'], ['super_admin','rmc_admin'])) {
            $status = $_GET['status'] ?? '';
            $where  = $status ? "WHERE nr.status=?" : "";
            $params = $status ? [$status] : [];

            $stmt = $this->db->prepare(
                "SELECT nr.*, p.plot_no, s.code as sector_code,
                        u.full_name as owner_name, u.mobile,
                        ru.full_name as reviewed_by_name
                 FROM noc_requests nr
                 JOIN properties p ON p.id=nr.property_id
                 JOIN sectors s ON s.id=p.sector_id
                 JOIN owners o ON o.id=nr.owner_id
                 JOIN users u ON u.id=o.user_id
                 LEFT JOIN users ru ON ru.id=nr.reviewed_by
                 $where
                 ORDER BY nr.created_at DESC"
            );
        } else {
            $ownerStmt = $this->db->prepare("SELECT id FROM owners WHERE user_id=?");
            $ownerStmt->execute([$me['sub']]);
            $owner = $ownerStmt->fetch();

            $stmt   = $this->db->prepare(
                "SELECT nr.*, p.plot_no, s.code as sector_code
                 FROM noc_requests nr
                 JOIN properties p ON p.id=nr.property_id
                 JOIN sectors s ON s.id=p.sector_id
                 WHERE nr.owner_id=?
                 ORDER BY nr.created_at DESC"
            );
            $params = [$owner['id']];
        }

        $stmt->execute($params ?? []);
        Response::success($stmt->fetchAll());
    }

    public function approve(int $id): void {
        $me = AuthMiddleware::require('super_admin','rmc_admin');
        $v  = Validator::fromRequest();

        $nocNumber = 'NOC-' . date('Y') . '-' . str_pad($id, 5, '0', STR_PAD_LEFT);
        $expiresAt = date('Y-m-d', strtotime('+6 months'));

        $this->db->prepare(
            "UPDATE noc_requests
             SET status='approved', reviewed_by=?, review_note=?,
                 noc_number=?, issued_at=NOW(), expires_at=?
             WHERE id=?"
        )->execute([$me['sub'], $v->get('note'), $nocNumber, $expiresAt, $id]);

        $this->db->prepare(
            "UPDATE owners o
             JOIN noc_requests nr ON nr.owner_id=o.id
             SET o.noc_cleared=1, o.noc_issued_at=CURDATE()
             WHERE nr.id=?"
        )->execute([$id]);

        $nr = $this->db->prepare("SELECT owner_id FROM noc_requests WHERE id=?");
        $nr->execute([$id]);
        $req = $nr->fetch();
        if ($req) {
            $userStmt = $this->db->prepare("SELECT user_id FROM owners WHERE id=?");
            $userStmt->execute([$req['owner_id']]);
            $ownUser = $userStmt->fetch();
            if ($ownUser) {
                $this->db->prepare(
                    "INSERT INTO notifications (user_id, title, body, type)
                     VALUES (?, 'NOC Approved', ?, 'system')"
                )->execute([$ownUser['user_id'], "Your NOC ($nocNumber) has been approved. Valid until $expiresAt."]);
            }
        }

        Response::success(['noc_number' => $nocNumber, 'expires_at' => $expiresAt], 'NOC approved and issued.');
    }

    public function reject(int $id): void {
        $me = AuthMiddleware::require('super_admin','rmc_admin');
        $v  = Validator::fromRequest();
        $v->required('reason');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $this->db->prepare(
            "UPDATE noc_requests SET status='rejected', reviewed_by=?, review_note=? WHERE id=?"
        )->execute([$me['sub'], $v->get('reason'), $id]);

        Response::success(null, 'NOC request rejected.');
    }
}

$ctrl   = new NOCController();
$method = $_SERVER['REQUEST_METHOD'];
$id     = isset($_GET['id']) ? (int)$_GET['id'] : null;
$action = $_GET['action'] ?? '';

AuthMiddleware::user();

match (true) {
    $method === 'POST' && !$id                          => $ctrl->request(),
    $method === 'GET'                                   => $ctrl->index(),
    $method === 'POST' && $id && $action === 'approve'  => $ctrl->approve($id),
    $method === 'POST' && $id && $action === 'reject'   => $ctrl->reject($id),
    default => Response::error('Not found.', 404),
};
