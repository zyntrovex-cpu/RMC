<?php
require_once __DIR__ . '/../config/bootstrap.php';

class AuthController {
    private PDO $db;

    public function __construct() { $this->db = Database::get(); }

    public function login(): void {
        $v = Validator::fromRequest();
        // accept either 'mobile' or 'email' field as the username
        $login = $v->get('mobile') ?: $v->get('email');
        $pass  = $v->get('password');
        if (!$login || !$pass) Response::error('Username and password are required.', 422);

        $stmt = $this->db->prepare(
            "SELECT * FROM users WHERE (mobile = ? OR email = ?) AND status = 'active'"
        );
        $stmt->execute([$login, $login]);
        $user = $stmt->fetch();

        if (!$user || !password_verify($pass, $user['password_hash'])) {
            Response::error('Invalid username or password.', 401);
        }

        $this->db->prepare("UPDATE users SET last_login = NOW() WHERE id = ?")->execute([$user['id']]);
        unset($user['password_hash'], $user['otp_secret']);
        Response::success(['token' => AuthMiddleware::generate($user), 'user' => $user], 'Login successful.');
    }

    public function me(): void {
        $payload = AuthMiddleware::user();
        $stmt = $this->db->prepare(
            "SELECT id, full_name, cnic, mobile, email, role, status, last_login FROM users WHERE id = ?"
        );
        $stmt->execute([$payload['sub']]);
        Response::success($stmt->fetch());
    }

    public function changePassword(): void {
        $payload = AuthMiddleware::user();
        $v = Validator::fromRequest();
        $v->required('current_password')->required('new_password');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $stmt = $this->db->prepare("SELECT password_hash FROM users WHERE id = ?");
        $stmt->execute([$payload['sub']]);
        $user = $stmt->fetch();

        if (!password_verify($v->get('current_password'), $user['password_hash'])) {
            Response::error('Current password is incorrect.', 403);
        }

        $hash = password_hash($v->get('new_password'), PASSWORD_BCRYPT, ['cost' => 12]);
        $this->db->prepare("UPDATE users SET password_hash = ? WHERE id = ?")->execute([$hash, $payload['sub']]);
        Response::success(null, 'Password updated successfully.');
    }
}

$ctrl   = new AuthController();
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

match (true) {
    $method === 'POST' && $action === 'login'           => $ctrl->login(),
    $method === 'GET'  && $action === 'me'              => $ctrl->me(),
    $method === 'POST' && $action === 'change-password' => $ctrl->changePassword(),
    default => Response::error('Endpoint not found.', 404),
};
