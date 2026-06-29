<?php
require_once __DIR__ . '/../config/bootstrap.php';

class ComplaintController {
    private PDO $db;

    public function __construct() {
        $this->db = Database::get();
    }

    public function index(): void {
        $me      = AuthMiddleware::user();
        $page    = max(1, (int)($_GET['page'] ?? 1));
        $perPage = 20;
        $offset  = ($page - 1) * $perPage;

        $where = ['1=1']; $params = [];

        if (in_array($me['role'], ['owner','tenant'])) {
            $propStmt = $this->db->prepare("SELECT id FROM properties WHERE registered_user_id=?");
            $propStmt->execute([$me['sub']]);
            $prop = $propStmt->fetch();
            if ($prop) { $where[] = 'c.property_id=?'; $params[] = $prop['id']; }
        } else {
            if (!empty($_GET['status']))    { $where[] = 'c.status=?';     $params[] = $_GET['status']; }
            if (!empty($_GET['type']))      { $where[] = 'c.type=?';       $params[] = $_GET['type']; }
            if (!empty($_GET['priority'])){ $where[] = 'c.priority=?';    $params[] = $_GET['priority']; }
            if (!empty($_GET['sector_id'])) { $where[] = 'p.sector_id=?'; $params[] = $_GET['sector_id']; }
        }

        $whereStr = implode(' AND ', $where);
        $countStmt = $this->db->prepare(
            "SELECT COUNT(*) FROM complaints c
             JOIN properties p ON p.id=c.property_id WHERE $whereStr"
        );
        $countStmt->execute($params);
        $total = (int)$countStmt->fetchColumn();

        $stmt = $this->db->prepare(
            "SELECT c.*, p.plot_no, s.code as sector_code,
                    u.full_name as submitted_by,
                    au.full_name as assigned_to_name
             FROM complaints c
             JOIN properties p ON p.id=c.property_id
             JOIN sectors s ON s.id=p.sector_id
             JOIN users u ON u.id=c.user_id
             LEFT JOIN users au ON au.id=c.assigned_to
             WHERE $whereStr
             ORDER BY FIELD(c.priority,'urgent','high','medium','low'), c.created_at DESC
             LIMIT $perPage OFFSET $offset"
        );
        $stmt->execute($params);
        Response::paginated($stmt->fetchAll(), $total, $page, $perPage);
    }

    public function store(): void {
        $me = AuthMiddleware::require('owner','tenant','super_admin','rmc_admin');
        $v  = Validator::fromRequest();
        $v->required('type')->required('title')->required('description');
        $v->inList('type', ['maintenance','water','security','electricity','cleanliness','noise','other']);
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $propId = $v->get('property_id');
        if (!$propId) {
            $propStmt = $this->db->prepare("SELECT id FROM properties WHERE registered_user_id=?");
            $propStmt->execute([$me['sub']]);
            $prop   = $propStmt->fetch();
            $propId = $prop['id'] ?? null;
        }
        if (!$propId) Response::error('No property found for this account.', 404);

        $this->db->prepare(
            "INSERT INTO complaints (property_id, user_id, type, title, description, priority)
             VALUES (?,?,?,?,?,?)"
        )->execute([
            $propId, $me['sub'],
            $v->get('type'), $v->get('title'), $v->get('description'),
            $v->get('priority', 'medium'),
        ]);
        $id = (int)$this->db->lastInsertId();

        $this->notifyAdmins($id, $v->get('title'));
        $this->show($id);
    }

    public function show(int $id): void {
        $stmt = $this->db->prepare(
            "SELECT c.*, p.plot_no, s.code as sector_code,
                    u.full_name as submitted_by, u.mobile as submitter_mobile,
                    au.full_name as assigned_to_name
             FROM complaints c
             JOIN properties p ON p.id=c.property_id
             JOIN sectors s ON s.id=p.sector_id
             JOIN users u ON u.id=c.user_id
             LEFT JOIN users au ON au.id=c.assigned_to
             WHERE c.id=?"
        );
        $stmt->execute([$id]);
        $complaint = $stmt->fetch();
        if (!$complaint) Response::error('Complaint not found.', 404);

        $commStmt = $this->db->prepare(
            "SELECT cc.*, u.full_name, u.role
             FROM complaint_comments cc
             JOIN users u ON u.id=cc.user_id
             WHERE cc.complaint_id=?
             ORDER BY cc.created_at"
        );
        $commStmt->execute([$id]);
        $complaint['comments'] = $commStmt->fetchAll();

        Response::success($complaint);
    }

    public function update(int $id): void {
        $me = AuthMiddleware::require('super_admin','rmc_admin','data_entry');
        $v  = Validator::fromRequest();

        $allowed = ['status','priority','assigned_to','resolution_note'];
        $set = []; $params = [];
        foreach ($allowed as $f) {
            if ($v->get($f) !== null) { $set[] = "$f=?"; $params[] = $v->get($f); }
        }

        if ($v->get('status') === 'resolved') {
            $set[] = 'resolved_at=NOW()';
        }

        if (!empty($set)) {
            $params[] = $id;
            $this->db->prepare("UPDATE complaints SET " . implode(',', $set) . " WHERE id=?")->execute($params);
        }

        if ($v->get('comment')) {
            $this->db->prepare(
                "INSERT INTO complaint_comments (complaint_id, user_id, comment, is_internal)
                 VALUES (?,?,?,?)"
            )->execute([$id, $me['sub'], $v->get('comment'), $v->get('is_internal', 0)]);
        }

        if ($v->get('status')) $this->notifyResident($id, $v->get('status'));

        $this->show($id);
    }

    public function addComment(int $id): void {
        $me = AuthMiddleware::user();
        $v  = Validator::fromRequest();
        $v->required('comment');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $isInternal = in_array($me['role'], ['super_admin','rmc_admin','data_entry']) && $v->get('is_internal') ? 1 : 0;

        $this->db->prepare(
            "INSERT INTO complaint_comments (complaint_id, user_id, comment, is_internal)
             VALUES (?,?,?,?)"
        )->execute([$id, $me['sub'], $v->get('comment'), $isInternal]);

        Response::success(null, 'Comment added.');
    }

    private function notifyAdmins(int $complaintId, string $title): void {
        $admins = $this->db->query(
            "SELECT id FROM users WHERE role IN ('super_admin','rmc_admin') AND status='active'"
        )->fetchAll();
        foreach ($admins as $admin) {
            $this->db->prepare(
                "INSERT INTO notifications (user_id, title, body, type)
                 VALUES (?, 'New Complaint Filed', ?, 'system')"
            )->execute([$admin['id'], "Complaint: $title"]);
        }
    }

    private function notifyResident(int $complaintId, string $status): void {
        $stmt = $this->db->prepare("SELECT user_id FROM complaints WHERE id=?");
        $stmt->execute([$complaintId]);
        $c = $stmt->fetch();
        if ($c) {
            $this->db->prepare(
                "INSERT INTO notifications (user_id, title, body, type)
                 VALUES (?, 'Complaint Update', ?, 'system')"
            )->execute([$c['user_id'], "Your complaint status has been updated to: $status"]);
        }
    }
}

$ctrl   = new ComplaintController();
$method = $_SERVER['REQUEST_METHOD'];
$id     = isset($_GET['id']) ? (int)$_GET['id'] : null;
$action = $_GET['action'] ?? '';

AuthMiddleware::user();

match (true) {
    $method === 'POST' && $id && $action === 'comment' => $ctrl->addComment($id),
    $method === 'GET'  && $id                          => $ctrl->show($id),
    $method === 'GET'                                  => $ctrl->index(),
    $method === 'POST' && !$id                         => $ctrl->store(),
    $method === 'PUT'  && $id                          => $ctrl->update($id),
    default => Response::error('Endpoint not found.', 404),
};
