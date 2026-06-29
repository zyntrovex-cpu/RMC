<?php
require_once __DIR__ . '/../config/bootstrap.php';

class UserController {
    private PDO $db;

    public function __construct() {
        $this->db = Database::get();
    }

    public function index(): void {
        $page    = max(1, (int)($_GET['page'] ?? 1));
        $perPage = min(100, (int)($_GET['per_page'] ?? 25));
        $offset  = ($page - 1) * $perPage;

        $where = ['1=1']; $params = [];
        if (!empty($_GET['role'])) {
            $where[] = 'role = ?'; $params[] = $_GET['role'];
        }
        if (!empty($_GET['status'])) {
            $where[] = 'status = ?'; $params[] = $_GET['status'];
        }
        if (!empty($_GET['search'])) {
            $where[] = '(full_name LIKE ? OR cnic LIKE ? OR mobile LIKE ? OR email LIKE ?)';
            $s = '%' . $_GET['search'] . '%';
            $params = array_merge($params, [$s, $s, $s, $s]);
        }

        $whereStr = implode(' AND ', $where);

        $countStmt = $this->db->prepare("SELECT COUNT(*) FROM users WHERE $whereStr");
        $countStmt->execute($params);
        $total = (int) $countStmt->fetchColumn();

        $stmt = $this->db->prepare(
            "SELECT u.id, u.full_name, u.cnic, u.mobile, u.whatsapp, u.email, u.role, u.status, u.last_login, u.created_at,
                    p.plot_no, s.name as sector_name
             FROM users u
             LEFT JOIN properties p ON p.registered_user_id = u.id
             LEFT JOIN sectors s ON s.id = p.sector_id
             WHERE $whereStr
             ORDER BY u.full_name
             LIMIT $perPage OFFSET $offset"
        );
        $stmt->execute($params);
        Response::paginated($stmt->fetchAll(), $total, $page, $perPage);
    }

    public function show(int $id): void {
        $stmt = $this->db->prepare(
            "SELECT id, full_name, cnic, mobile, mobile_alt, whatsapp, email, role, status, last_login, created_at
             FROM users WHERE id = ?"
        );
        $stmt->execute([$id]);
        $user = $stmt->fetch();
        if (!$user) Response::error('User not found.', 404);

        $propStmt = $this->db->prepare(
            "SELECT p.plot_no, s.code as sector, pc.label as category, p.occupancy, ow.transfer_date
             FROM ownership_records ow
             JOIN properties p ON p.id = ow.property_id
             JOIN sectors s ON s.id = p.sector_id
             JOIN property_categories pc ON pc.id = p.category_id
             JOIN owners o ON o.id = ow.owner_id
             WHERE o.user_id = ?"
        );
        $propStmt->execute([$id]);
        $user['properties'] = $propStmt->fetchAll();

        Response::success($user);
    }

    public function store(): void {
        AuthMiddleware::require('super_admin', 'rmc_admin');
        $v = Validator::fromRequest();
        $v->required('full_name')->required('role');
        $v->email('email')->cnic('cnic');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $password = $v->get('password') ?: bin2hex(random_bytes(6));
        $hash     = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);

        $this->db->prepare(
            "INSERT INTO users (full_name, cnic, mobile, mobile_alt, whatsapp, email, password_hash, role)
             VALUES (?,?,?,?,?,?,?,?)"
        )->execute([
            $v->get('full_name'), $v->get('cnic'), $v->get('mobile'),
            $v->get('mobile_alt'), $v->get('whatsapp'), $v->get('email'),
            $hash, $v->get('role'),
        ]);

        $userId = (int) $this->db->lastInsertId();

        if ($v->get('role') === 'owner') {
            $this->db->prepare(
                "INSERT INTO owners (user_id, permanent_address, ownership_doc_ref) VALUES (?,?,?)"
            )->execute([$userId, $v->get('permanent_address'), $v->get('ownership_doc_ref')]);
        } elseif ($v->get('role') === 'tenant') {
            $this->db->prepare(
                "INSERT INTO tenants (user_id, emergency_contact) VALUES (?,?)"
            )->execute([$userId, $v->get('emergency_contact')]);
        }

        $admin = AuthMiddleware::user();
        $this->db->prepare(
            "INSERT INTO audit_log (user_id, action, entity_type, entity_id, new_value)
             VALUES (?, 'user.create', 'user', ?, ?)"
        )->execute([$admin['sub'], $userId, json_encode(['role' => $v->get('role'), 'name' => $v->get('full_name')])]);

        $this->show($userId);
    }

    public function update(int $id): void {
        AuthMiddleware::require('super_admin', 'rmc_admin');
        $v = Validator::fromRequest();
        $v->email('email')->cnic('cnic');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $allowed = ['full_name','cnic','mobile','mobile_alt','whatsapp','email','status'];
        $set = []; $params = [];
        foreach ($allowed as $f) {
            if ($v->get($f) !== null) {
                $set[] = "$f = ?"; $params[] = $v->get($f);
            }
        }
        if (empty($set)) Response::error('No fields to update.', 400);
        $params[] = $id;
        $this->db->prepare("UPDATE users SET " . implode(', ', $set) . " WHERE id = ?")->execute($params);
        $this->show($id);
    }

    public function resetPassword(int $id): void {
        AuthMiddleware::require('super_admin', 'rmc_admin');
        $v = Validator::fromRequest();
        if ($v->get('new_password')) {
            $hash = password_hash($v->get('new_password'), PASSWORD_BCRYPT, ['cost' => 12]);
        } else {
            $newPass = bin2hex(random_bytes(6));
            $hash    = password_hash($newPass, PASSWORD_BCRYPT, ['cost' => 12]);
        }
        $this->db->prepare("UPDATE users SET password_hash=? WHERE id=?")->execute([$hash, $id]);
        Response::success(['temporary_password' => $newPass ?? null], 'Password reset successfully.');
    }
}

$ctrl   = new UserController();
$method = $_SERVER['REQUEST_METHOD'];
$id     = isset($_GET['id']) ? (int)$_GET['id'] : null;
$action = $_GET['action'] ?? '';

AuthMiddleware::require('super_admin', 'rmc_admin', 'data_entry');

match (true) {
    $method === 'POST' && $id && $action === 'reset-password' => $ctrl->resetPassword($id),
    $method === 'GET'  && $id                                  => $ctrl->show($id),
    $method === 'GET'                                          => $ctrl->index(),
    $method === 'POST' && !$id                                 => $ctrl->store(),
    $method === 'PUT'  && $id                                  => $ctrl->update($id),
    default => Response::error('Endpoint not found.', 404),
};
