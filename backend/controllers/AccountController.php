<?php
require_once __DIR__ . '/../config/bootstrap.php';

class AccountController {
    private PDO $db;
    public function __construct() { $this->db = Database::get(); }

    public function index(): void {
        $rows = $this->db->query("SELECT * FROM accounts ORDER BY sort_order, name")->fetchAll();
        Response::success($rows);
    }

    public function store(): void {
        AuthMiddleware::require('super_admin');
        $v = Validator::fromRequest();
        $v->required('name')->required('code')->required('monthly_amount');
        $v->numeric('monthly_amount');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $this->db->prepare(
            "INSERT INTO accounts (name, code, description, monthly_amount, sort_order) VALUES (?,?,?,?,?)"
        )->execute([
            $v->get('name'), strtoupper($v->get('code')), $v->get('description'),
            $v->get('monthly_amount'), $v->get('sort_order', 0),
        ]);
        Response::success(['id' => $this->db->lastInsertId()], 'Account created.');
    }

    public function update(int $id): void {
        AuthMiddleware::require('super_admin', 'rmc_admin');
        $v = Validator::fromRequest();
        $admin = AuthMiddleware::user();

        if ($v->get('monthly_amount') !== null) {
            $old = $this->db->prepare("SELECT monthly_amount FROM accounts WHERE id=?");
            $old->execute([$id]);
            $oldAmt = $old->fetchColumn();

            $this->db->prepare(
                "INSERT INTO account_rate_history (account_id, old_amount, new_amount, effective_from, changed_by, reason)
                 VALUES (?,?,?,?,?,?)"
            )->execute([$id, $oldAmt, $v->get('monthly_amount'), $v->get('effective_from', date('Y-m-d')), $admin['sub'], $v->get('reason')]);

            $this->db->prepare("UPDATE accounts SET monthly_amount=? WHERE id=?")
                     ->execute([$v->get('monthly_amount'), $id]);
        }

        $allowed = ['name','description','is_active','sort_order'];
        $set = []; $params = [];
        foreach ($allowed as $f) {
            if ($v->get($f) !== null) { $set[] = "$f = ?"; $params[] = $v->get($f); }
        }
        if (!empty($set)) {
            $params[] = $id;
            $this->db->prepare("UPDATE accounts SET " . implode(', ', $set) . " WHERE id=?")->execute($params);
        }

        $stmt = $this->db->prepare("SELECT * FROM accounts WHERE id=?");
        $stmt->execute([$id]);
        Response::success($stmt->fetch());
    }

    public function rateHistory(): void {
        $stmt = $this->db->prepare(
            "SELECT arh.*, u.full_name as changed_by_name, a.name as account_name
             FROM account_rate_history arh
             LEFT JOIN users u ON u.id = arh.changed_by
             JOIN accounts a ON a.id = arh.account_id
             ORDER BY arh.created_at DESC LIMIT 50"
        );
        $stmt->execute();
        Response::success($stmt->fetchAll());
    }
}

$ctrl = new AccountController();
$method = $_SERVER['REQUEST_METHOD'];
$id = isset($_GET['id']) ? (int)$_GET['id'] : null;
$action = $_GET['action'] ?? '';
AuthMiddleware::require('super_admin', 'rmc_admin', 'data_entry');

match (true) {
    $method === 'GET' && $action === 'rate-history' => $ctrl->rateHistory(),
    $method === 'GET' => $ctrl->index(),
    $method === 'POST' && !$id => $ctrl->store(),
    $method === 'PUT' && $id => $ctrl->update($id),
    default => Response::error('Endpoint not found.', 404),
};
