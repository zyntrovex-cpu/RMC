<?php
require_once __DIR__ . '/../config/bootstrap.php';

class VisitorController {
    private PDO $db;

    public function __construct() {
        $this->db = Database::get();
    }

    public function myPasses(): void {
        $me = AuthMiddleware::require('owner','tenant');
        $propStmt = $this->db->prepare("SELECT id FROM properties WHERE registered_user_id=?");
        $propStmt->execute([$me['sub']]);
        $prop = $propStmt->fetch();
        if (!$prop) Response::error('No property linked.', 404);

        $stmt = $this->db->prepare(
            "SELECT * FROM visitor_passes WHERE property_id=?
             ORDER BY created_at DESC LIMIT 30"
        );
        $stmt->execute([$prop['id']]);
        Response::success($stmt->fetchAll());
    }

    public function create(): void {
        $me = AuthMiddleware::require('owner','tenant');
        $v  = Validator::fromRequest();
        $v->required('visitor_name')->required('visit_date')->required('valid_from')->required('valid_until');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $propStmt = $this->db->prepare("SELECT id FROM properties WHERE registered_user_id=?");
        $propStmt->execute([$me['sub']]);
        $prop = $propStmt->fetch();
        if (!$prop) Response::error('No property linked.', 404);

        $passCode = strtoupper(substr(md5(uniqid(mt_rand(), true)), 0, 6));

        $this->db->prepare(
            "INSERT INTO visitor_passes
                (property_id, registered_by, visitor_name, visitor_cnic, visitor_mobile,
                 vehicle_no, purpose, visit_date, valid_from, valid_until, pass_code)
             VALUES (?,?,?,?,?,?,?,?,?,?,?)"
        )->execute([
            $prop['id'], $me['sub'],
            $v->get('visitor_name'), $v->get('visitor_cnic'), $v->get('visitor_mobile'),
            $v->get('vehicle_no'), $v->get('purpose'),
            $v->get('visit_date'), $v->get('valid_from'), $v->get('valid_until'),
            $passCode,
        ]);

        Response::success(['pass_code' => $passCode], 'Visitor pass created. Share the code with your visitor.', 201);
    }

    public function verify(): void {
        AuthMiddleware::require('super_admin','rmc_admin','data_entry');
        $v = Validator::fromRequest();
        $v->required('pass_code');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $stmt = $this->db->prepare(
            "SELECT vp.*, p.plot_no, s.code as sector_code, u.full_name as host
             FROM visitor_passes vp
             JOIN properties p ON p.id=vp.property_id
             JOIN sectors s ON s.id=p.sector_id
             JOIN users u ON u.id=vp.registered_by
             WHERE vp.pass_code=? AND vp.status='active'
               AND NOW() BETWEEN vp.valid_from AND vp.valid_until"
        );
        $stmt->execute([strtoupper($v->get('pass_code'))]);
        $pass = $stmt->fetch();

        if (!$pass) Response::error('Invalid, expired, or already used pass code.', 404);

        $this->db->prepare("UPDATE visitor_passes SET status='used', used_at=NOW() WHERE id=?")->execute([$pass['id']]);

        Response::success($pass, 'Pass verified. Visitor may enter.');
    }

    public function cancel(int $id): void {
        AuthMiddleware::require('owner','tenant','super_admin','rmc_admin');
        $this->db->prepare("UPDATE visitor_passes SET status='cancelled' WHERE id=?")->execute([$id]);
        Response::success(null, 'Pass cancelled.');
    }
}

$ctrl   = new VisitorController();
$method = $_SERVER['REQUEST_METHOD'];
$id     = isset($_GET['id']) ? (int)$_GET['id'] : null;
$action = $_GET['action'] ?? '';

AuthMiddleware::user();

match (true) {
    $method === 'GET'  && $action === 'my-passes'     => $ctrl->myPasses(),
    $method === 'POST' && $action === 'verify'        => $ctrl->verify(),
    $method === 'POST' && !$id                        => $ctrl->create(),
    $method === 'POST' && $id && $action === 'cancel' => $ctrl->cancel($id),
    default => Response::error('Not found.', 404),
};
